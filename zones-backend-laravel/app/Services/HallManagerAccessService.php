<?php

namespace App\Services;

use App\Models\Station;
use App\Models\User;

class HallManagerAccessService
{
    /**
     * @var list<string>
     */
    private const HALL_EMPLOYEE_ROLES = ['reception', 'maintenance'];

    public function syncFromManagerStatus(User $manager, bool $active): void
    {
        if ($active) {
            $this->enableManagerHall($manager);

            return;
        }

        $this->disableManagerHall($manager);
    }

    public function disableManagerHall(User $manager): void
    {
        if (! $manager->hasRole('manager')) {
            return;
        }

        $station = $manager->managedStation;
        if (! $station instanceof Station) {
            return;
        }

        $station->update([
            'is_active' => false,
            'bookings_enabled' => false,
        ]);

        User::query()
            ->where('station_id', $station->id)
            ->where('id', '!=', $manager->id)
            ->whereHas('roles', fn ($query) => $query->whereIn('name', self::HALL_EMPLOYEE_ROLES))
            ->update(['account_status' => 'inactive']);
    }

    public function enableManagerHall(User $manager): void
    {
        if (! $manager->hasRole('manager')) {
            return;
        }

        $station = $manager->managedStation;
        if (! $station instanceof Station) {
            return;
        }

        $station->update([
            'is_active' => true,
            'bookings_enabled' => true,
        ]);
    }
}
