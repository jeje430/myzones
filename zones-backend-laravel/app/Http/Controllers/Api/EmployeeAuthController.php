<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class EmployeeAuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'station_id' => 'required|integer|exists:stations,id',
            'role' => 'required|in:reception,maintenance',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials'],
            ]);
        }

        if ($user->account_status !== 'active') {
            return response()->json([
                'message' => 'Account is inactive',
            ], 403);
        }

        if (! $user->hasAnyRole(['reception', 'maintenance'])) {
            return response()->json([
                'message' => 'This login is for employee accounts only',
            ], 403);
        }

        $stationId = $user->resolvedStationId();
        if (! $stationId) {
            return response()->json([
                'message' => 'Employee is not linked to a station',
            ], 403);
        }

        if ((int) $stationId !== (int) $request->station_id) {
            return response()->json([
                'message' => 'Employee does not belong to this station',
            ], 403);
        }

        if (! $user->hasRole($request->role)) {
            return response()->json([
                'message' => 'Employee role does not match',
            ], 403);
        }

        $user->update(['last_login_at' => now()]);
        $user->refresh()->load(['roles', 'station']);

        $token = $user->createToken('employee_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
        ]);
    }
}
