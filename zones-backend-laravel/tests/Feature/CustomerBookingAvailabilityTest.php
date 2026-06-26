<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\Package;
use App\Models\Station;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class CustomerBookingAvailabilityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer');
    }

    public function test_customer_can_check_lounge_availability(): void
    {
        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        $station = Station::create([
            'name' => 'Control Gaming',
            'slug' => 'control-gaming',
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
        ]);

        $package = Package::create([
            'station_id' => $station->id,
            'name' => 'PS5 Standard',
            'slug' => 'ps5-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 25,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        Device::create([
            'station_id' => $station->id,
            'package_id' => $package->id,
            'device_code' => 'PS5-01',
            'display_name' => 'PS5-01',
            'device_type' => 'ps5',
            'operational_status' => 'active',
        ]);

        $date = now()->addDay()->format('Y-m-d');

        $response = $this->withToken($token)->getJson(
            "/api/lounges/{$station->id}/availability?package_id={$package->id}&date={$date}",
        );

        $response->assertOk()
            ->assertJsonPath('station_id', $station->id)
            ->assertJsonPath('package_id', $package->id)
            ->assertJsonStructure(['is_available', 'message', 'slots']);
    }
}
