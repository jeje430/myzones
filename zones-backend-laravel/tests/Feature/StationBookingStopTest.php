<?php

namespace Tests\Feature;

use App\Models\Package;
use App\Models\Station;
use App\Models\StationBookingStop;
use App\Models\User;
use App\Support\BookingStopReason;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class StationBookingStopTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Role::findOrCreate('manager');
        Role::findOrCreate('customer');
    }

    public function test_manager_can_create_open_ended_booking_stop(): void
    {
        [$station, $manager] = $this->createFixture();

        Sanctum::actingAs($manager);

        $response = $this->postJson('/api/manager/booking-stops', [
            'reason_key' => BookingStopReason::POWER_OUTAGE,
            'starts_on' => now()->toDateString(),
            'ends_on' => null,
        ]);

        $response->assertCreated()
            ->assertJsonPath('active.open_ended', true)
            ->assertJsonPath('active.reason_key', BookingStopReason::POWER_OUTAGE);

        $this->assertDatabaseHas('station_booking_stops', [
            'station_id' => $station->id,
            'status' => 'active',
            'ends_on' => null,
        ]);
    }

    public function test_availability_blocked_during_stop_period(): void
    {
        [$station, $manager, $package] = $this->createFixture(withPackage: true);

        $customer = User::factory()->create();
        $customer->assignRole('customer');

        \App\Models\Device::create([
            'station_id' => $station->id,
            'package_id' => $package->id,
            'device_code' => 'PS5-01',
            'display_name' => 'PS5-01',
            'device_type' => 'ps5',
            'operational_status' => 'active',
        ]);

        StationBookingStop::create([
            'station_id' => $station->id,
            'reason_key' => BookingStopReason::HALL_MAINTENANCE,
            'starts_on' => now()->toDateString(),
            'ends_on' => now()->addDays(3)->toDateString(),
            'status' => 'active',
            'created_by' => $manager->id,
        ]);

        $date = now()->toDateString();

        $response = $this->actingAs($customer, 'sanctum')->getJson(
            "/api/lounges/{$station->id}/availability?package_id={$package->id}&date={$date}",
        );

        $response->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonStructure(['booking_stop' => ['message', 'button_label']]);
    }

    public function test_stop_auto_expires_after_end_date(): void
    {
        [$station] = $this->createFixture();

        StationBookingStop::create([
            'station_id' => $station->id,
            'reason_key' => BookingStopReason::TECHNICAL_ISSUE,
            'starts_on' => now()->subDays(5)->toDateString(),
            'ends_on' => now()->subDay()->toDateString(),
            'status' => 'active',
        ]);

        $response = $this->getJson("/api/lounges/{$station->id}/booking-stop");

        $response->assertOk()
            ->assertJsonPath('is_blocked', false);

        $this->assertDatabaseHas('station_booking_stops', [
            'station_id' => $station->id,
            'status' => 'ended',
        ]);
    }

    public function test_manager_can_resume_booking_stop(): void
    {
        [$station, $manager] = $this->createFixture();

        $stop = StationBookingStop::create([
            'station_id' => $station->id,
            'reason_key' => BookingStopReason::INTERNET_OUTAGE,
            'starts_on' => now()->toDateString(),
            'status' => 'active',
            'created_by' => $manager->id,
        ]);

        Sanctum::actingAs($manager);

        $response = $this->patchJson("/api/manager/booking-stops/{$stop->id}/resume");

        $response->assertOk()
            ->assertJsonPath('active', null);

        $this->assertDatabaseHas('station_booking_stops', [
            'id' => $stop->id,
            'status' => 'ended',
        ]);
    }

    /**
     * @return array{0: Station, 1: User, 2?: Package}
     */
    private function createFixture(bool $withPackage = false): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $station = Station::create([
            'name' => 'Stop Test Lounge',
            'slug' => 'stop-test-lounge',
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
            'manager_id' => $manager->id,
        ]);

        $manager->update(['station_id' => $station->id]);

        if (! $withPackage) {
            return [$station, $manager];
        }

        $package = Package::create([
            'station_id' => $station->id,
            'name' => 'PS5 Standard',
            'slug' => 'ps5-stop-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 50,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        return [$station, $manager, $package];
    }
}
