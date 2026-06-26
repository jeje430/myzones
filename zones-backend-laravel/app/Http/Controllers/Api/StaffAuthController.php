<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\BlocksDisabledAccounts;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class StaffAuthController extends Controller
{
    use BlocksDisabledAccounts;

  /** أدوار لوحة التحكم (غير الزبون). */
    private function staffRoles(): array
    {
        return ['manager', 'reception', 'maintenance', 'super_admin'];
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $email = strtolower(trim($request->email));
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials'],
            ]);
        }

        if ($this->accountLoginBlocked($user)) {
            return $this->blockedAccountResponse();
        }

        if (! $user->hasAnyRole($this->staffRoles())) {
            return response()->json([
                'message' => 'This login is for staff accounts only',
            ], 403);
        }

        $role = $user->getRoleNames()->first(
            fn ($name) => in_array($name, $this->staffRoles(), true)
        );

        if (in_array($role, ['manager', 'reception', 'maintenance'], true) && ! $user->resolvedStationId()) {
            return response()->json([
                'message' => 'Account is not linked to a station',
            ], 403);
        }

        $user->update(['last_login_at' => now()]);
        $user->refresh()->load(['roles', 'station', 'managedStation']);

        $tokenName = match ($role) {
            'super_admin' => 'super_admin_token',
            'manager' => 'manager_token',
            default => 'employee_token',
        };

        $token = $user->createToken($tokenName)->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
            'role' => $role,
        ]);
    }
}
