<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SuperAdminStaffController extends Controller
{
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
        ]);

        $roleFilter = $validated['role'] ?? null;

        $staff = User::query()
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
            ],
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function mapStaffMember(User $user): array
    {
        $role = $this->resolvePrimaryStaffRole($user);

        return [
            'id' => $user->id,
            'name' => $user->full_name,
            'email' => $user->email,
            'role' => $role,
            'role_label' => $this->roleLabel($role),
            'status' => $this->normalizeStatus($user->account_status),
            'account_status' => $user->account_status,
            'created_at' => $user->created_at?->format('Y-m-d'),
            'hall_name' => $user->managedStation?->name ?? $user->station?->name,
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
