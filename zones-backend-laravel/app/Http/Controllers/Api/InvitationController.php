<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Invitation;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;

class InvitationController extends Controller
{

    // Send Invitation
    public function sendInvitation(Request $request)
    {

        $request->validate([

            'name' => 'required|string|max:255',

            'station_name' => 'required|string|max:255',

            'email' => 'required|email',

            'role' => 'required|string',

        ]);

        $user = $request->user();

        // super admin can invite manager only
        if (
            $user->hasRole('super_admin') &&
            $request->role !== 'manager'
        ) {

            return response()->json([

                'message' => 'Super admin can invite managers only',

            ], 403);

        }

        // manager can invite reception and maintenance only
        if (
            $user->hasRole('manager') &&
            !in_array($request->role, ['reception', 'maintenance'])
        ) {

            return response()->json([

                'message' => 'Manager can invite employees only',

            ], 403);

        }

        // other roles cannot send invitations
        if (
            !$user->hasRole('super_admin') &&
            !$user->hasRole('manager')
        ) {

            return response()->json([

                'message' => 'Unauthorized',

            ], 403);

        }

        // create invitation
        $invitation = Invitation::create([

            'name' => $request->name,

            'station_name' => $request->station_name,

            'email' => $request->email,

            'role' => $request->role,

            'token' => Str::random(64),

            'invited_by' => $request->user()->id,

            'expires_at' => now()->addDays(7),

        ]);

        return response()->json([

            'message' => 'Invitation created successfully',

            'invitation' => $invitation,

            'register_link' => url('/register/' . $invitation->token),

        ]);

    }

    // Complete Registration
    public function completeRegistration(Request $request)
    {

        $request->validate([

            'token' => 'required|string',

            'password' => 'required|min:6|confirmed',

        ]);

        // find invitation
        $invitation = Invitation::where(
            'token',
            $request->token
        )->first();

        // invitation not found
        if (!$invitation) {

            return response()->json([

                'message' => 'Invalid invitation token',

            ], 404);

        }

        // invitation already used
        if ($invitation->used_at !== null) {

            return response()->json([

                'message' => 'Invitation already used',

            ], 400);

        }

        // invitation expired
        if ($invitation->expires_at < now()) {

            return response()->json([

                'message' => 'Invitation expired',

            ], 400);

        }

        // create user
        $user = User::create([

            'full_name' => $invitation->name,

            'email' => $invitation->email,

            'password' => Hash::make($request->password),

        ]);

        // assign role
        $user->assignRole($invitation->role);

        // mark invitation as used
        $invitation->update([

            'used_at' => now(),

        ]);

        // create token
        $token = $user->createToken(
            'auth_token'
        )->plainTextToken;

        return response()->json([

            'message' => 'Account created successfully',

            'token' => $token,

            'user' => $user,

            'role' => $invitation->role,

        ]);

    }

}
