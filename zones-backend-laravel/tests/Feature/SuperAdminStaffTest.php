<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class SuperAdminStaffTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (['customer', 'manager', 'reception', 'maintenance', 'super_admin'] as $role) {
            Role::findOrCreate($role);
        }
    }

    public function test_super_admin_can_list_dashboard_staff_only(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $manager = User::factory()->create(['full_name' => 'Manager One']);
        $manager->assignRole('manager');

        $reception = User::factory()->create(['full_name' => 'Reception One']);
        $reception->assignRole('reception');

        $customer = User::factory()->create(['full_name' => 'Customer One']);
        $customer->assignRole('customer');

        $response = $this->withToken($token)
            ->getJson('/api/super-admin/staff')
            ->assertOk();

        $names = collect($response->json('staff'))->pluck('name')->all();

        $this->assertContains('Manager One', $names);
        $this->assertContains('Reception One', $names);
        $this->assertNotContains('Customer One', $names);
        $this->assertNotContains($admin->full_name, $names);
    }

    public function test_non_super_admin_cannot_list_dashboard_staff(): void
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');
        $token = $manager->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/super-admin/staff')
            ->assertForbidden();
    }

    public function test_staff_response_includes_required_fields(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $employee = User::factory()->create([
            'full_name' => 'Staff Member',
            'email' => 'staff@example.com',
            'account_status' => 'active',
        ]);
        $employee->assignRole('maintenance');

        $this->withToken($token)
            ->getJson('/api/super-admin/staff')
            ->assertOk()
            ->assertJsonFragment([
                'name' => 'Staff Member',
                'email' => 'staff@example.com',
                'role' => 'maintenance',
                'status' => 'active',
            ]);
    }
}
