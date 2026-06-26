<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesStaffStation;
use App\Http\Controllers\Controller;
use App\Models\StaffNotification;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StaffNotificationController extends Controller
{
    use ResolvesStaffStation;

    public function index(Request $request): JsonResponse
    {
        $user = $this->staffUser($request);
        $station = $this->resolveStaffStation($user);

        $notifications = StaffNotification::query()
            ->where('user_id', $user->id)
            ->when($station, fn ($q) => $q->where(function ($inner) use ($station) {
                $inner->whereNull('station_id')
                    ->orWhere('station_id', $station->id);
            }))
            ->orderByDesc('id')
            ->limit(50)
            ->get()
            ->map(fn (StaffNotification $n) => $this->mapNotification($n));

        $unreadCount = StaffNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'notifications' => $notifications,
            'unread_count' => $unreadCount,
        ]);
    }

    public function markRead(Request $request, StaffNotification $notification): JsonResponse
    {
        $user = $this->staffUser($request);

        if ((int) $notification->user_id !== (int) $user->id) {
            return response()->json(['message' => 'الإشعار غير موجود'], 404);
        }

        if (! $notification->read_at) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json([
            'message' => 'تم تعليم الإشعار كمقروء',
            'notification' => $this->mapNotification($notification->fresh()),
        ]);
    }

    public function destroy(Request $request, StaffNotification $notification): JsonResponse
    {
        $user = $this->staffUser($request);

        if ((int) $notification->user_id !== (int) $user->id) {
            return response()->json(['message' => 'الإشعار غير موجود'], 404);
        }

        $notification->delete();

        return response()->json(['message' => 'تم حذف الإشعار']);
    }

    public function destroyBatch(Request $request): JsonResponse
    {
        $user = $this->staffUser($request);
        $ids = $request->validate([
            'ids' => ['required', 'array', 'min:1'],
            'ids.*' => ['integer'],
        ])['ids'];

        $deleted = StaffNotification::query()
            ->where('user_id', $user->id)
            ->whereIn('id', $ids)
            ->delete();

        return response()->json([
            'message' => 'تم حذف الإشعارات المحددة',
            'deleted' => $deleted,
        ]);
    }

    public function destroyAll(Request $request): JsonResponse
    {
        $user = $this->staffUser($request);

        $deleted = StaffNotification::query()
            ->where('user_id', $user->id)
            ->delete();

        return response()->json([
            'message' => 'تم حذف جميع الإشعارات',
            'deleted' => $deleted,
        ]);
    }

    private function mapNotification(StaffNotification $notification): array
    {
        $payload = $notification->payload ?? [];

        return [
            'id' => $notification->id,
            'type' => $notification->type,
            'title' => $notification->title,
            'body' => $notification->body,
            'message' => $notification->body,
            'name' => $notification->title,
            'severity' => $payload['severity'] ?? 'medium',
            'instructions' => $payload['alternative_instructions'] ?? '',
            'payload' => $payload,
            'read_at' => $notification->read_at?->toIso8601String(),
            'is_read' => $notification->read_at !== null,
            'createdAt' => $notification->created_at?->toIso8601String(),
            'created_at' => $notification->created_at?->toIso8601String(),
        ];
    }

    private function staffUser(Request $request): User
    {
        $user = $request->user();
        if (! $user instanceof User || ! $user->hasAnyRole(['manager', 'reception', 'maintenance'])) {
            abort(403, 'غير مصرح');
        }

        return $user;
    }
}
