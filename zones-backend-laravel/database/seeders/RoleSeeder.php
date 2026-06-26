<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

class RoleSeeder extends Seeder
{
    /**
     * Seed application roles used by Spatie Permission.
     */
    public function run(): void
    {
        $roles = [
            'customer',
            'manager',
            'reception',
            'maintenance',
            'super_admin',
        ];

        foreach ($roles as $role) {
            Role::firstOrCreate([
                'name' => $role,
                'guard_name' => 'web',
            ]);
        }
    }
}
