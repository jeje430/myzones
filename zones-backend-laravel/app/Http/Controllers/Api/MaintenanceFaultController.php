<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesStaffStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\DeviceFaultResource;
use App\Http\Resources\DeviceResource;
use App\Models\Device;
use App\Models\DeviceFault;
use App\Models\User;
use App\Services\MaintenanceExpenseService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class MaintenanceFaultController extends Controller
{
    use ResolvesStaffStation;

    public function index(Request $request): JsonResponse
    {
        $station = $this->resolveStaffStation($request->user());
        if (! $station) {
            return response()->json(['message' => 'لا توجد صالة مرتبطة بهذا الحساب'], 404);
        }

        $archived = $request->boolean('archived');

        $faults = DeviceFault::query()
            ->with(['device.package'])
            ->where('station_id', $station->id)
            ->where('archived', $archived)
            ->orderByDesc('reported_at')
            ->get();

        return response()->json([
            'faults' => DeviceFaultResource::collection($faults)->resolve(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user instanceof User || ! $user->hasAnyRole(['manager', 'maintenance'])) {
            return response()->json(['message' => 'غير مصرح'], 403);
        }

        $station = $this->resolveStaffStation($user);
        if (! $station) {
            return response()->json(['message' => 'لا توجد صالة مرتبطة بهذا الحساب'], 404);
        }

        $validated = $request->validate([
            'device_id' => 'required|integer',
            'fault_type' => 'required|string|max:40',
            'fault_type_custom' => 'nullable|string|max:120',
            'details' => 'nullable|string|max:2000',
            'maintenance_employee_name' => 'nullable|string|max:120',
            'reported_at' => 'nullable|date_format:Y-m-d',
            'apply_maintenance_now' => 'nullable|boolean',
        ]);

        $device = Device::query()
            ->where('station_id', $station->id)
            ->whereKey($validated['device_id'])
            ->first();

        if (! $device) {
            return response()->json(['message' => 'الجهاز غير موجود في هذه الصالة'], 404);
        }

        $hasOpenFault = DeviceFault::query()
            ->where('device_id', $device->id)
            ->where('archived', false)
            ->whereIn('status', ['pending', 'in_progress'])
            ->exists();

        if ($hasOpenFault) {
            throw ValidationException::withMessages([
                'device_id' => ['هذا الجهاز له عطل معلّق بالفعل'],
            ]);
        }

        $result = DB::transaction(function () use ($validated, $device, $station, $user, $request) {
            $tz = config('app.timezone', 'Africa/Tripoli');
            $reportedAt = isset($validated['reported_at'])
                ? Carbon::parse($validated['reported_at'], $tz)->startOfDay()
                : Carbon::now($tz)->startOfDay();

            $today = Carbon::now($tz)->startOfDay();
            $applyNow = $request->has('apply_maintenance_now')
                ? $request->boolean('apply_maintenance_now')
                : $reportedAt->lessThanOrEqualTo($today);

            $fault = DeviceFault::create([
                'station_id' => $station->id,
                'device_id' => $device->id,
                'reported_by' => $user->id,
                'fault_type' => $validated['fault_type'],
                'fault_type_custom' => $validated['fault_type_custom'] ?? null,
                'details' => $validated['details'] ?? null,
                'status' => 'pending',
                'maintenance_employee_name' => $validated['maintenance_employee_name'] ?? $user->name,
                'reported_at' => $reportedAt,
            ]);

            if ($applyNow) {
                $device->update([
                    'operational_status' => 'maintenance',
                ]);
            }

            return compact('fault', 'applyNow');
        });

        $fault = $result['fault'];
        $applyNow = $result['applyNow'];

        $fault->load(['device.package', 'device.openFault']);

        return response()->json([
            'message' => $applyNow
                ? 'تم تسجيل العطل ووضع الجهاز في الصيانة'
                : 'تم جدولة العطل — الجهاز يبقى متاحاً حتى التاريخ المحدد',
            'fault' => (new DeviceFaultResource($fault))->resolve(),
            'device' => (new DeviceResource($fault->device->fresh()->load('openFault')))->resolve(),
            'apply_maintenance_now' => $applyNow,
            'cancelled_bookings_count' => 0,
            'cancelled_bookings' => [],
        ], 201);
    }

    public function start(Request $request, DeviceFault $fault): JsonResponse
    {
        $station = $this->resolveStaffStation($request->user());
        if (! $station || (int) $fault->station_id !== (int) $station->id) {
            return response()->json(['message' => 'العطل غير موجود'], 404);
        }

        if ($fault->archived || $fault->status === 'resolved') {
            throw ValidationException::withMessages([
                'fault' => ['لا يمكن بدء الإصلاح لعطل مؤرشف'],
            ]);
        }

        $fault->update(['status' => 'in_progress']);

        $device = $fault->device()->first();
        if ($device && $device->operational_status !== 'maintenance') {
            $device->update(['operational_status' => 'maintenance']);
        }

        $fault->load(['device.package', 'device.openFault']);

        return response()->json([
            'message' => 'بدأ الإصلاح',
            'fault' => (new DeviceFaultResource($fault))->resolve(),
            'device' => (new DeviceResource($fault->device))->resolve(),
        ]);
    }

    public function resolve(Request $request, DeviceFault $fault): JsonResponse
    {
        $station = $this->resolveStaffStation($request->user());
        if (! $station || (int) $fault->station_id !== (int) $station->id) {
            return response()->json(['message' => 'العطل غير موجود'], 404);
        }

        if ($fault->archived) {
            throw ValidationException::withMessages([
                'fault' => ['العطل مؤرشف بالفعل'],
            ]);
        }

        $validated = $request->validate([
            'maintenance_cost' => 'nullable|numeric|min:0',
        ]);

        $actor = $request->user();
        if (! $actor instanceof User) {
            return response()->json(['message' => 'غير مصرح'], 403);
        }

        $expenseService = app(MaintenanceExpenseService::class);

        $device = DB::transaction(function () use ($fault, $validated, $actor, $expenseService) {
            $fault->update([
                'status' => 'resolved',
                'archived' => true,
                'resolved_at' => now(),
                'maintenance_cost' => $validated['maintenance_cost'] ?? $fault->maintenance_cost,
            ]);

            $device = $fault->device()->first();
            if ($device) {
                $device->update([
                    'operational_status' => 'active',
                    'last_maintenance_at' => now(),
                ]);
            }

            $expenseService->createFromResolvedFault($fault->fresh(), $actor);

            return $device;
        });

        $fault->load(['device.package']);

        return response()->json([
            'message' => 'تم إتمام الإصلاح — الجهاز متاح للحجز',
            'fault' => (new DeviceFaultResource($fault))->resolve(),
            'device' => $device ? (new DeviceResource($device->fresh()))->resolve() : null,
        ]);
    }
}
