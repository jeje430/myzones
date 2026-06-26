<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\User;
use App\Support\AccountAccess;
use Illuminate\Http\JsonResponse;

trait BlocksDisabledAccounts
{
    protected function blockedAccountResponse(): JsonResponse
    {
        return response()->json([
            'message' => AccountAccess::DISABLED_MESSAGE,
        ], 403);
    }

    protected function accountLoginBlocked(User $user): bool
    {
        if ($user->account_status !== 'active') {
            return true;
        }

        if ($user->hasRole('manager')) {
            $station = $user->managedStation;

            return ! $station || ! $station->is_active;
        }

        if ($user->hasAnyRole(['reception', 'maintenance'])) {
            $station = $user->station;
            if (! $station || ! $station->is_active) {
                return true;
            }

            $station->loadMissing('manager');

            return ! $station->manager || $station->manager->account_status !== 'active';
        }

        return false;
    }
}
