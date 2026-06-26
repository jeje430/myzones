<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\HallManagerAccessService;
use App\Support\WorkShiftSchedule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SuperAdminStaffController extends Controller
{
    public function __construct(
        private readonly HallManagerAccessService $hallManagerAccess,
    ) {}
    /**
     * Dashboard staff roles only — excludes customers and super admins.
     *
     * @var list<string>
     */
    public const DASHBOARD_STAFF_ROLES = ['manager', 'reception', 'maintenance'];

    /**
     * Roles that must never appear in this listing.
     *
     * @var list<string>
     */
    private const EXCLUDED_ROLES = ['customer', 'super_admin'];

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'role' => 'sometimes|in:manager,reception,maintenance,employee',
            'archived' => 'sometimes|boolean',
        ]);

        $roleFilter = $validated['role'] ?? null;
        $archivedOnly = (bool) ($validated['archived'] ?? false);

        $query = User::query();

        if ($archivedOnly) {
            $query->onlyTrashed();
        }

        $staff = $query
            ->whereHas('roles', function ($query) use ($roleFilter) {
                if ($roleFilter === 'employee') {
                    $query->whereIn('name', ['reception', 'maintenance']);
                } elseif ($roleFilter) {
                    $query->where('name', $roleFilter);
                } else {
                    $query->whereIn('name', self::DASHBOARD_STAFF_ROLES);
                }
            })
            ->whereDoesntHave('roles', fn ($query) => $query->whereIn('name', self::EXCLUDED_ROLES))
            ->with(['roles', 'station', 'managedStation'])
            ->latest()
            ->get()
            ->map(fn (User $user) => $this->mapStaffMember($user))
            ->values();

        return response()->json([
            'staff' => $staff,
            'meta' => [
                'total' => $staff->count(),
                'roles_included' => self::DASHBOARD_STAFF_ROLES,
                'archived' => $archivedOnly,
            ],
        ]);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $this->assertMutableDashboardStaff($user);

        $validated = $request->validate([
            'account_status' => 'required|in:active,inactive,suspended',
        ]);

        $user->update(['account_status' => $validated['account_status']]);

        if ($user->hasRole('manager')) {
            $this->hallManagerAccess->syncFromManagerStatus(
                $user,
                $validated['account_status'] === 'active',
            );
        }

        $user->load(['roles', 'station', 'managedStation']);

        return response()->json([
            'message' => 'تم تحديث حالة الحساب',
            'staff' => $this->mapStaffMember($user),
        ]);
    }

    public function destroy(User $user): JsonResponse
    {
        $this->assertMutableDashboardStaff($user);

        $user->delete();

        return response()->json([
            'message' => 'تمت أرشفة الحساب',
        ]);
    }

    public function restore(int $user): JsonResponse
    {
        $member = User::onlyTrashed()->findOrFail($user);
        $this->assertMutableDashboardStaff($member);

        $member->restore();
        $member->load(['roles', 'station', 'managedStation']);

        return response()->json([
            'message' => 'تم استرجاع الحساب من الأرشيف',
            'staff' => $this->mapStaffMember($member),
        ]);
    }

    private function assertMutableDashboardStaff(User $user): void
    {
        abort_if($user->hasAnyRole(self::EXCLUDED_ROLES), 403, 'لا يمكن تعديل هذا الحساب');
        abort_unless($user->hasAnyRole(self::DASHBOARD_STAFF_ROLES), 403, 'لا يمكن تعديل هذا الحساب');
    }

    /**
     * @return array<string, mixed>
     */
    private function mapStaffMember(User $user): array
    {
        $role = $this->resolvePrimaryStaffRole($user);
        $hallAssignment = $this->resolveHallAssignment($user, $hallName = $user->managedStation?->name ?? $user->station?->name);

        return [
            'id' => $user->id,
            'name' => $user->full_name,
            'email' => $user->email,
            'phone' => $user->phone ?? '',
            'role' => $role,
            'role_label' => $this->roleLabel($role),
            'work_shift' => $user->work_shift,
            'shift_label' => WorkShiftSchedule::periodLabel($user->work_shift),
            'working_hours' => WorkShiftSchedule::workingHours($user->work_shift),
            'status' => $this->normalizeStatus($user->account_status),
            'account_status' => $user->account_status,
            'created_at' => $user->created_at?->format('Y-m-d'),
            'hall_name' => $hallAssignment['hall_name'],
            'hall_scope' => $hallAssignment['hall_scope'],
            'hall_label' => $hallAssignment['hall_label'],
            'assigned_halls' => $hallAssignment['hall_name'] ? [$hallAssignment['hall_name']] : [],
            'archived_at' => $user->deleted_at?->format('Y-m-d'),
            'status_note' => $this->resolveStatusNote($user),
        ];
    }

    private function resolveStatusNote(User $user): ?string
    {
        if ($user->account_status === 'active') {
            return null;
        }

        if (! $user->hasAnyRole(['reception', 'maintenance'])) {
            return null;
        }

        $station = $user->station;
        if (! $station) {
            return null;
        }

        $station->loadMissing('manager');
        $managerDisabled = $station->manager && $station->manager->account_status !== 'active';
        $hallDisabled = ! $station->is_active || $managerDisabled;

        return $hallDisabled ? 'معطّل بسبب تعطيل الصالة' : null;
    }

    /**
     * @return array{hall_name: ?string, hall_scope: string, hall_label: string}
     */
    private function resolveHallAssignment(User $user, ?string $hallName): array
    {
        if ($hallName) {
            return [
                'hall_name' => $hallName,
                'hall_scope' => 'assigned',
                'hall_label' => $hallName,
            ];
        }

        if ($user->hasRole('super_admin')) {
            return [
                'hall_name' => null,
                'hall_scope' => 'global',
                'hall_label' => 'كل الصالات',
            ];
        }

        return [
            'hall_name' => null,
            'hall_scope' => 'unassigned',
            'hall_label' => 'غير مرتبطة',
        ];
    }

    private function resolvePrimaryStaffRole(User $user): ?string
    {
        $roles = $user->roles->pluck('name');

        foreach (self::DASHBOARD_STAFF_ROLES as $staffRole) {
            if ($roles->contains($staffRole)) {
                return $staffRole;
            }
        }

        return $roles->first();
    }

    private function roleLabel(?string $role): string
    {
        return match ($role) {
            'manager' => 'مدير صالة',
            'reception' => 'موظف استقبال',
            'maintenance' => 'موظف صيانة',
            default => 'موظف',
        };
    }

    private function normalizeStatus(?string $accountStatus): string
    {
        return $accountStatus === 'active' ? 'active' : 'inactive';
    }
}
