<?php

namespace Tests\Feature;

use App\Models\Station;
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

    public function test_super_admin_can_filter_managers(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $manager = User::factory()->create(['full_name' => 'Manager Filter']);
        $manager->assignRole('manager');

        $reception = User::factory()->create(['full_name' => 'Reception Filter']);
        $reception->assignRole('reception');

        $names = collect(
            $this->withToken($token)
                ->getJson('/api/super-admin/staff?role=manager')
                ->assertOk()
                ->json('staff')
        )->pluck('name')->all();

        $this->assertContains('Manager Filter', $names);
        $this->assertNotContains('Reception Filter', $names);
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
            'phone' => '0911111111',
            'account_status' => 'active',
            'work_shift' => 'morning',
        ]);
        $employee->assignRole('maintenance');

        $station = Station::create([
            'name' => 'Control Gaming',
            'slug' => 'control-gaming-staff-test',
            'is_active' => true,
            'is_published' => true,
        ]);
        $employee->update(['station_id' => $station->id]);

        $this->withToken($token)
            ->getJson('/api/super-admin/staff')
            ->assertOk()
            ->assertJsonFragment([
                'name' => 'Staff Member',
                'email' => 'staff@example.com',
                'phone' => '0911111111',
                'role' => 'maintenance',
                'status' => 'active',
                'shift_label' => 'الفترة الأولى',
                'working_hours' => 'من 2 مساءً إلى 8 مساءً',
                'hall_name' => 'Control Gaming',
                'hall_scope' => 'assigned',
                'hall_label' => 'Control Gaming',
            ]);
    }

    public function test_super_admin_can_toggle_staff_status(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $employee = User::factory()->create(['account_status' => 'active']);
        $employee->assignRole('reception');

        $this->withToken($token)
            ->patchJson("/api/super-admin/staff/{$employee->id}", [
                'account_status' => 'inactive',
            ])
            ->assertOk()
            ->assertJsonPath('staff.account_status', 'inactive');

        $this->assertDatabaseHas('users', [
            'id' => $employee->id,
            'account_status' => 'inactive',
        ]);
    }

    public function test_super_admin_can_archive_and_restore_staff(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $employee = User::factory()->create();
        $employee->assignRole('maintenance');

        $this->withToken($token)
            ->deleteJson("/api/super-admin/staff/{$employee->id}")
            ->assertOk();

        $this->assertSoftDeleted('users', ['id' => $employee->id]);

        $this->withToken($token)
            ->getJson('/api/super-admin/staff?archived=1')
            ->assertOk()
            ->assertJsonFragment(['name' => $employee->full_name]);

        $this->withToken($token)
            ->postJson("/api/super-admin/staff/{$employee->id}/restore")
            ->assertOk();

        $this->assertDatabaseHas('users', [
            'id' => $employee->id,
            'deleted_at' => null,
        ]);
    }

    public function test_manager_deactivation_cascades_to_station_and_employees(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $manager = User::factory()->create(['account_status' => 'active']);
        $manager->assignRole('manager');

        $station = Station::create([
            'name' => 'Test Hall',
            'slug' => 'test-hall',
            'manager_id' => $manager->id,
            'is_active' => true,
            'is_published' => true,
        ]);

        $employee = User::factory()->create([
            'station_id' => $station->id,
            'account_status' => 'active',
        ]);
        $employee->assignRole('reception');

        $this->withToken($token)
            ->patchJson("/api/super-admin/staff/{$manager->id}", [
                'account_status' => 'inactive',
            ])
            ->assertOk();

        $this->assertDatabaseHas('stations', [
            'id' => $station->id,
            'is_active' => false,
            'bookings_enabled' => false,
        ]);

        $this->assertDatabaseHas('users', [
            'id' => $employee->id,
            'account_status' => 'inactive',
        ]);
    }
}
