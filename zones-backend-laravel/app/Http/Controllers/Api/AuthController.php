<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\GoogleIdTokenVerifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'full_name' => 'required_without:name|string|max:255',
            'name' => 'required_without:full_name|string|max:255',
            'phone' => ['required', 'string', 'max:20', Rule::unique('users', 'phone')->whereNull('deleted_at')],
            'email' => ['required', 'email', Rule::unique('users', 'email')->whereNull('deleted_at')],
            'password' => 'required|min:6|confirmed',
        ]);

        $fullName = $request->input('full_name', $request->input('name'));
        $email = $request->email;

        $trashedUser = User::onlyTrashed()->where('email', $email)->first();

        if ($trashedUser) {
            $trashedUser->restore();
            $trashedUser->update([
                'full_name' => $fullName,
                'phone' => $request->phone,
                'password' => $request->password,
                'account_status' => 'active',
            ]);
            $trashedUser->syncRoles(['customer']);
            $user = $trashedUser;
        } else {
            $user = User::create([
                'full_name' => $fullName,
                'phone' => $request->phone,
                'email' => $email,
                'password' => $request->password,
                'account_status' => 'active',
            ]);

            $user->assignRole('customer');
        }
        $user->load('roles');

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'User registered successfully',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user) {
            if (User::onlyTrashed()->where('email', $request->email)->exists()) {
                return response()->json([
                    'message' => 'This account has been deleted. Please create a new account.',
                ], 403);
            }

            throw ValidationException::withMessages([
                'email' => ['Invalid credentials'],
            ]);
        }

        if (! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials'],
            ]);
        }

        if ($user->account_status !== 'active') {
            return response()->json([
                'message' => 'This account has been deleted. Please create a new account.',
            ], 403);
        }

        if (! $user->hasRole('customer')) {
            return response()->json([
                'message' => 'This login is for customer accounts only',
            ], 403);
        }

        $user->update([
            'last_login_at' => now(),
        ]);

        $user->refresh()->load('roles');

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ]);
    }

    public function loginWithGoogle(Request $request, GoogleIdTokenVerifier $verifier): JsonResponse
    {
        $request->validate([
            'id_token' => 'required|string',
        ]);

        $identity = $verifier->verify($request->string('id_token')->toString());

        if (! $identity) {
            return response()->json([
                'message' => 'Invalid Google token',
            ], 401);
        }

        $user = User::query()
            ->where('google_id', $identity['google_id'])
            ->first();

        if (! $user) {
            $user = User::query()->where('email', $identity['email'])->first();
        }

        if ($user && $user->trashed()) {
            return response()->json([
                'message' => 'This account has been deleted. Please create a new account.',
            ], 403);
        }

        if (! $user) {
            $user = User::create([
                'full_name' => $identity['name'],
                'email' => $identity['email'],
                'google_id' => $identity['google_id'],
                'password' => Hash::make(Str::random(40)),
                'account_status' => 'active',
                'email_verified_at' => now(),
            ]);
            $user->assignRole('customer');
        } else {
            if ($user->account_status !== 'active') {
                return response()->json([
                    'message' => 'This account has been deleted. Please create a new account.',
                ], 403);
            }

            if (! $user->hasRole('customer')) {
                return response()->json([
                    'message' => 'This login is for customer accounts only',
                ], 403);
            }

            $user->update([
                'google_id' => $identity['google_id'],
                'last_login_at' => now(),
            ]);
        }

        $user->refresh()->load('roles');

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully',
        ]);
    }

    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()->load(['roles', 'station', 'managedStation']);

        return response()->json([
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $request->validate([
            'full_name' => 'required_without:name|string|max:255',
            'name' => 'required_without:full_name|string|max:255',
            'phone' => 'nullable|string|max:20|unique:users,phone,'.$user->id,
        ]);

        $user->update([
            'full_name' => $request->input('full_name', $request->input('name', $user->full_name)),
            'phone' => $request->phone ?? $user->phone,
        ]);

        $user->load('roles');

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => new UserResource($user),
        ]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => 'required',
            'new_password' => 'required|min:6|confirmed',
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect',
            ], 400);
        }

        $user->update([
            'password' => $request->new_password,
        ]);

        return response()->json([
            'message' => 'Password changed successfully',
        ]);
    }

    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->hasRole('customer') && ! $user->hasRole('manager') && ! $user->hasRole('super_admin')) {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $user->tokens()->delete();

        $user->update([
            'account_status' => 'inactive',
        ]);

        $user->delete();

        return response()->json([
            'message' => 'Account deleted successfully',
        ]);
    }
}
