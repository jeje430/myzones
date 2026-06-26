<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class SuperAdminAuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'full_name' => 'required_without:name|string|max:255',
            'name' => 'required_without:full_name|string|max:255',
            'phone' => ['required', 'string', 'max:20', Rule::unique('users', 'phone')->whereNull('deleted_at')],
            'email' => ['required', 'email', Rule::unique('users', 'email')->whereNull('deleted_at')],
            'password' => 'required|min:8|confirmed',
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
            $trashedUser->syncRoles(['super_admin']);
            $user = $trashedUser;
        } else {
            $user = User::create([
                'full_name' => $fullName,
                'phone' => $request->phone,
                'email' => $email,
                'password' => $request->password,
                'account_status' => 'active',
            ]);

            $user->assignRole('super_admin');
        }

        $user->load('roles');

        return response()->json([
            'message' => 'Super admin registered successfully',
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

        if (! $user->hasRole('super_admin')) {
            return response()->json([
                'message' => 'This login is for super admin accounts only',
            ], 403);
        }

        $user->update([
            'last_login_at' => now(),
        ]);

        $user->refresh()->load('roles');

        $token = $user->createToken('super_admin_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ]);
    }
}
