<?php

namespace Tests\Feature;

use App\Models\Offer;
use App\Models\Package;
use App\Models\Station;
use App\Models\Tournament;
use App\Models\User;
use App\Support\AccountAccess;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class HallManagerDisableTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private string $adminToken;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (['customer', 'manager', 'reception', 'maintenance', 'super_admin'] as $role) {
            Role::findOrCreate($role);
        }

        $this->admin = User::factory()->create();
        $this->admin->assignRole('super_admin');
        $this->adminToken = $this->admin->createToken('test')->plainTextToken;
    }

    public function test_disabling_manager_hides_hall_ecosystem_from_public_apis(): void
    {
        [$manager, $station, $employee, $offer, $tournament] = $this->createPublishedHallEcosystem();

        $this->assertHallVisibleInPublicApis($station, $offer, $tournament);

        $this->withToken($this->adminToken)
            ->patchJson("/api/super-admin/staff/{$manager->id}", [
                'account_status' => 'inactive',
            ])
            ->assertOk()
            ->assertJsonPath('staff.account_status', 'inactive');

        $this->assertDatabaseHas('stations', [
            'id' => $station->id,
            'is_active' => false,
            'bookings_enabled' => false,
        ]);

        $this->assertDatabaseHas('users', [
            'id' => $employee->id,
            'account_status' => 'inactive',
        ]);

        $this->postJson('/api/manager/login', [
            'email' => $manager->email,
            'password' => 'password',
            'station_id' => $station->id,
        ])->assertForbidden()
            ->assertJsonPath('message', AccountAccess::DISABLED_MESSAGE);

        $this->postJson('/api/employee/login', [
            'email' => $employee->email,
            'password' => 'password',
            'station_id' => $station->id,
            'role' => 'reception',
        ])->assertForbidden()
            ->assertJsonPath('message', AccountAccess::DISABLED_MESSAGE);

        $this->getJson('/api/lounges')
            ->assertOk()
            ->assertJsonMissing(['id' => $station->id]);

        $this->getJson("/api/lounges/{$station->id}")
            ->assertNotFound();

        $offerIds = collect($this->getJson('/api/offers')->assertOk()->json())->pluck('id');
        $this->assertFalse($offerIds->contains($offer->id));

        $tournamentIds = collect($this->getJson('/api/tournaments')->assertOk()->json())->pluck('id');
        $this->assertFalse($tournamentIds->contains($tournament->id));

        $this->withToken($this->adminToken)
            ->getJson('/api/super-admin/staff?role=employee')
            ->assertOk()
            ->assertJsonFragment([
                'id' => $employee->id,
                'status_note' => 'معطّل بسبب تعطيل الصالة',
            ]);
    }

    public function test_reactivating_manager_restores_hall_without_auto_enabling_employees(): void
    {
        [$manager, $station, $employee] = $this->createPublishedHallEcosystem();

        $this->withToken($this->adminToken)
            ->patchJson("/api/super-admin/staff/{$manager->id}", [
                'account_status' => 'inactive',
            ])
            ->assertOk();

        $this->withToken($this->adminToken)
            ->patchJson("/api/super-admin/staff/{$manager->id}", [
                'account_status' => 'active',
            ])
            ->assertOk();

        $this->assertDatabaseHas('stations', [
            'id' => $station->id,
            'is_active' => true,
            'bookings_enabled' => true,
        ]);

        $this->assertDatabaseHas('users', [
            'id' => $employee->id,
            'account_status' => 'inactive',
        ]);

        $this->getJson('/api/lounges')
            ->assertOk()
            ->assertJsonFragment(['id' => (string) $station->id]);
    }

    /**
     * @return array{0: User, 1: Station, 2: User, 3: Offer, 4: Tournament}
     */
    private function createPublishedHallEcosystem(): array
    {
        $manager = User::factory()->create([
            'account_status' => 'active',
            'password' => Hash::make('password'),
        ]);
        $manager->assignRole('manager');

        $station = Station::create([
            'name' => 'Disable Test Hall',
            'slug' => 'disable-test-hall',
            'manager_id' => $manager->id,
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
            'latitude' => 32.88,
            'longitude' => 13.19,
        ]);

        $employee = User::factory()->create([
            'station_id' => $station->id,
            'account_status' => 'active',
            'password' => Hash::make('password'),
        ]);
        $employee->assignRole('reception');

        $package = Package::create([
            'station_id' => $station->id,
            'name' => 'PS5 Hour',
            'slug' => 'ps5-disable-test',
            'package_type' => 'ps5',
            'hourly_price' => 25,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        $offer = Offer::create([
            'station_id' => $station->id,
            'package_id' => $package->id,
            'title' => 'Weekend Deal',
            'description' => 'Test offer',
            'valid_from' => now()->subDay(),
            'expires_at' => now()->addWeek(),
            'original_price' => 50,
            'discounted_price' => 35,
            'is_active' => true,
        ]);

        $tournament = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Friday Cup',
            'game_name' => 'FIFA',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => now()->addDays(2),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => 'Standard rules',
            'status' => 'upcoming',
            'max_participants' => 16,
            'is_active' => true,
        ]);

        return [$manager, $station, $employee, $offer, $tournament];
    }

    private function assertHallVisibleInPublicApis(Station $station, Offer $offer, Tournament $tournament): void
    {
        $this->getJson('/api/lounges')
            ->assertOk()
            ->assertJsonFragment(['id' => (string) $station->id]);

        $this->getJson("/api/lounges/{$station->id}")
            ->assertOk()
            ->assertJsonPath('id', (string) $station->id);

        $offerIds = collect($this->getJson('/api/offers')->assertOk()->json())->pluck('id');
        $this->assertTrue($offerIds->contains($offer->id));

        $tournamentIds = collect($this->getJson('/api/tournaments')->assertOk()->json())->pluck('id');
        $this->assertTrue($tournamentIds->contains($tournament->id));
    }
}
