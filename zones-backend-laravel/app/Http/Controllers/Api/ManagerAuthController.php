<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class ManagerAuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'station_id' => 'required|integer|exists:stations,id',
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

        if (! $user->hasRole('manager')) {
            return response()->json([
                'message' => 'This login is for manager accounts only',
            ], 403);
        }

        if (! $user->resolvedStationId()) {
            return response()->json([
                'message' => 'Manager is not linked to a station',
            ], 403);
        }

        if ((int) $user->resolvedStationId() !== (int) $request->station_id) {
            return response()->json([
                'message' => 'Manager does not belong to this station',
            ], 403);
        }

        $user->update(['last_login_at' => now()]);
        $user->refresh()->load(['roles', 'station', 'managedStation']);

        $token = $user->createToken('manager_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
        ]);
    }
}
