<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Models\Role;

class AuthController extends Controller
{

    // Register
    public function register(Request $request)
    {

        $request->validate([

            'full_name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:20',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:6|confirmed',

        ]);

        $user = User::create([

            'full_name' => $request->full_name,
            'phone' => $request->phone,
            'email' => $request->email,
            'password' => Hash::make($request->password),

        ]);

        // assign customer role with api guard
        $user->assignRole('customer');

        $token = $user->createToken(
            'auth_token'
        )->plainTextToken;

        return response()->json([

            'message' => 'User registered successfully',

            'token' => $token,

            'user' => $user,

        ]);

    }

    // Login
    public function login(Request $request)
    {

        $request->validate([

            'email' => 'required|email',

            'password' => 'required',

        ]);

        $user = User::where(
            'email',
            $request->email
        )->first();

        if (
            !$user ||
            !Hash::check(
                $request->password,
                $user->password
            )
        ) {

            throw ValidationException::withMessages([

                'email' => ['Invalid credentials'],

            ]);

        }

        // check account status
        if ($user->account_status !== 'active') {

            return response()->json([

                'message' => 'Account is inactive',

            ], 403);

        }

        $token = $user->createToken(
            'auth_token'
        )->plainTextToken;

        return response()->json([

            'message' => 'Login successful',

            'token' => $token,

            'user' => $user,

            'roles' => $user->getRoleNames(),

            'permissions' => $user->getAllPermissions(),

        ]);

    }

    // Logout
    public function logout(Request $request)
    {

        $request->user()
            ->currentAccessToken()
            ->delete();

        return response()->json([

            'message' => 'Logged out successfully',

        ]);

    }

    // Profile
    public function profile(Request $request)
    {

        return response()->json([

            'user' => $request->user(),

            'roles' => $request->user()->getRoleNames(),

            'permissions' => $request->user()->getAllPermissions(),

        ]);

    }

    // Update Profile
    public function updateProfile(Request $request)
    {

        $user = $request->user();

        $request->validate([

            'full_name' => 'required|string|max:255',

            'phone' => 'nullable|string|max:20',

            'profile_image' => 'nullable|string',

        ]);

        $user->update([

            'full_name' => $request->full_name,

            'phone' => $request->phone,

            'profile_image' => $request->profile_image,

        ]);

        return response()->json([

            'message' => 'Profile updated successfully',

            'user' => $user,

        ]);

    }

    // Change Password
    public function changePassword(Request $request)
    {

        $request->validate([

            'current_password' => 'required',

            'new_password' => 'required|min:6|confirmed',

        ]);

        $user = $request->user();

        // check current password
        if (
            !Hash::check(
                $request->current_password,
                $user->password
            )
        ) {

            return response()->json([

                'message' => 'Current password is incorrect',

            ], 400);

        }

        // update password
        $user->update([

            'password' => Hash::make(
                $request->new_password
            ),

        ]);

        return response()->json([

            'message' => 'Password changed successfully',

        ]);

    }

    // Delete Account
    public function deleteAccount(Request $request)
    {

        $user = $request->user();

        // allowed only customer and manager
        if (
            !$user->hasRole('customer') &&
            !$user->hasRole('manager')
        ) {

            return response()->json([

                'message' => 'Unauthorized',

            ], 403);

        }

        // deactivate account
        $user->update([

            'account_status' => 'inactive',

        ]);

        // delete current token
        $request->user()
            ->currentAccessToken()
            ->delete();

        return response()->json([

            'message' => 'Account deleted successfully',

        ]);

    }

}
