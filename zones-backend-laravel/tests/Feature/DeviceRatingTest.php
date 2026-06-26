<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\DeviceRating;
use App\Models\Package;
use App\Models\Station;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class DeviceRatingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer');
        Role::findOrCreate('manager');
    }

    public function test_customer_can_submit_device_ratings(): void
    {
        [$station, $package, $customer] = $this->createPublishedLoungeFixture();
        Sanctum::actingAs($customer);

        $response = $this->postJson("/api/lounges/{$station->id}/device-ratings", [
            'ratings' => [
                [
                    'device_id' => $package->id,
                    'rating_value' => 4,
                    'comment' => 'جهاز ممتاز',
                ],
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('ratings.0.device_id', (string) $package->id)
            ->assertJsonPath('ratings.0.rating_value', 4);

        $this->assertDatabaseHas('device_ratings', [
            'user_id' => $customer->id,
            'package_id' => $package->id,
            'rating_value' => 4,
        ]);

        $package->refresh();
        $this->assertEquals(4.0, (float) $package->average_rating);
        $this->assertEquals(1, $package->ratings_count);
    }

    public function test_duplicate_rating_updates_existing_record(): void
    {
        [$station, $package, $customer] = $this->createPublishedLoungeFixture();
        Sanctum::actingAs($customer);

        $this->postJson("/api/lounges/{$station->id}/device-ratings", [
            'ratings' => [
                ['device_id' => $package->id, 'rating_value' => 3],
            ],
        ])->assertCreated();

        $this->postJson("/api/lounges/{$station->id}/device-ratings", [
            'ratings' => [
                ['device_id' => $package->id, 'rating_value' => 5],
            ],
        ])->assertCreated();

        $this->assertEquals(1, DeviceRating::query()->count());

        $package->refresh();
        $this->assertEquals(5.0, (float) $package->average_rating);
        $this->assertEquals(1, $package->ratings_count);
    }

    public function test_customer_can_rate_multiple_devices_in_one_request(): void
    {
        [$station, $package, $customer] = $this->createPublishedLoungeFixture();

        $secondPackage = Package::create([
            'station_id' => $station->id,
            'name' => 'PC Gaming',
            'slug' => 'pc-'.$station->id,
            'package_type' => 'pc',
            'hourly_price' => 40,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        Device::create([
            'station_id' => $station->id,
            'package_id' => $secondPackage->id,
            'device_code' => 'PC-01',
            'display_name' => 'PC-01',
            'device_type' => 'pc',
            'operational_status' => 'active',
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson("/api/lounges/{$station->id}/device-ratings", [
            'ratings' => [
                ['device_id' => $package->id, 'rating_value' => 4],
                ['device_id' => $secondPackage->id, 'rating_value' => 5],
            ],
        ]);

        $response->assertCreated();
        $this->assertEquals(2, DeviceRating::query()->count());
    }

    public function test_rejects_device_not_belonging_to_station(): void
    {
        [$station, $package, $customer] = $this->createPublishedLoungeFixture();

        $otherStation = Station::create([
            'name' => 'Other Lounge',
            'slug' => 'other-lounge',
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
            'manager_id' => User::factory()->create()->id,
        ]);

        $foreignPackage = Package::create([
            'station_id' => $otherStation->id,
            'name' => 'Foreign',
            'slug' => 'foreign-'.$otherStation->id,
            'package_type' => 'ps5',
            'hourly_price' => 30,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        Sanctum::actingAs($customer);

        $this->postJson("/api/lounges/{$station->id}/device-ratings", [
            'ratings' => [
                ['device_id' => $foreignPackage->id, 'rating_value' => 4],
            ],
        ])->assertStatus(422);
    }

    public function test_catalog_includes_ratings_count_and_user_rating(): void
    {
        [$station, $package, $customer] = $this->createPublishedLoungeFixture();

        DeviceRating::create([
            'user_id' => $customer->id,
            'package_id' => $package->id,
            'rating_value' => 4,
        ]);

        $package->update(['average_rating' => 4, 'ratings_count' => 1]);

        Sanctum::actingAs($customer);

        $response = $this->getJson("/api/lounges/{$station->id}");

        $response->assertOk()
            ->assertJsonPath('devices.0.ratings_count', 1)
            ->assertJsonPath('devices.0.user_rating', 4)
            ->assertJsonPath('devices.0.average_rating', 4);
    }

    /**
     * @return array{0: Station, 1: Package, 2: User}
     */
    private function createPublishedLoungeFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $station = Station::create([
            'name' => 'Test Lounge',
            'slug' => 'test-lounge',
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
            'manager_id' => $manager->id,
        ]);

        $package = Package::create([
            'station_id' => $station->id,
            'name' => 'PS5 Standard',
            'slug' => 'ps5-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 50,
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

        $customer = User::factory()->create();
        $customer->assignRole('customer');

        return [$station, $package, $customer];
    }
}
