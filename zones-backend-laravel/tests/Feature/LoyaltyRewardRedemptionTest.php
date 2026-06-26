<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Device;
use App\Models\Package;
use App\Models\PlatformSetting;
use App\Models\Station;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class LoyaltyRewardRedemptionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer');
        Role::findOrCreate('reception');
    }

    public function test_customer_can_book_with_loyalty_reward_and_points_deduct(): void
    {
        PlatformSetting::current()->update([
            'loyalty_points_per_session' => 20,
            'loyalty_minimum_points_required' => 200,
        ]);

        $customer = User::factory()->create(['loyalty_points_balance' => 240]);
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        [$station, $package, $device] = $this->createStationFixture();

        $response = $this->withToken($token)->postJson('/api/bookings', [
            'station_id' => $station->id,
            'package_id' => $package->id,
            'device_id' => $device->id,
            'date' => now()->addDay()->format('Y-m-d'),
            'hour' => '14:00',
            'payment_method' => 'loyalty_reward',
        ]);

        $response->assertCreated()
            ->assertJsonPath('booking.payment_method', 'loyalty_reward')
            ->assertJsonPath('booking.booking_type', 'loyalty')
            ->assertJsonPath('booking.total_price', 0)
            ->assertJsonPath('loyalty.points_balance', 40);

        $this->assertDatabaseHas('users', [
            'id' => $customer->id,
            'loyalty_points_balance' => 40,
        ]);
    }

    public function test_session_end_awards_points_and_unlock_notification(): void
    {
        PlatformSetting::current()->update([
            'loyalty_points_per_session' => 20,
            'loyalty_minimum_points_required' => 200,
        ]);

        $customer = User::factory()->create(['loyalty_points_balance' => 180]);
        $customer->assignRole('customer');

        $reception = User::factory()->create(['station_id' => null]);
        $reception->assignRole('reception');
        $receptionToken = $reception->createToken('test')->plainTextToken;

        [$station, $package, $device] = $this->createStationFixture();
        $reception->update(['station_id' => $station->id]);

        $booking = Booking::create([
            'user_id' => $customer->id,
            'station_id' => $station->id,
            'device_id' => $device->id,
            'package_id' => $package->id,
            'booking_number' => 'APP-001',
            'booking_type' => 'regular',
            'visitor_name' => $customer->full_name,
            'visitor_phone' => $customer->phone,
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->format('Y-m-d'),
            'start_time' => '14:00',
            'end_time' => '15:00',
            'hours_count' => 1,
            'original_hourly_price' => 50,
            'discounted_hourly_price' => 50,
            'subtotal_price' => 50,
            'total_price' => 50,
            'payment_method' => 'cash',
            'payment_status' => 'pending',
            'booking_status' => 'confirmed',
            'session_status' => 'playing',
            'is_checked_in' => true,
            'session_started_at' => now()->subHour(),
            'booking_source' => 'mobile_app',
        ]);

        $response = $this->withToken($receptionToken)->postJson("/api/staff/reception/calendar/{$booking->id}/end");

        $response->assertOk()
            ->assertJsonPath('loyalty.earned', 20)
            ->assertJsonPath('loyalty.balance_after', 200);

        $this->assertDatabaseHas('customer_notifications', [
            'user_id' => $customer->id,
            'type' => 'loyalty_reward_unlocked',
        ]);
    }

    /**
     * @return array{0: Station, 1: Package, 2: Device}
     */
    private function createStationFixture(): array
    {
        $station = Station::create([
            'name' => 'Test Lounge',
            'slug' => 'test-lounge',
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
        ]);

        $package = Package::create([
            'station_id' => $station->id,
            'name' => 'Standard',
            'slug' => 'standard-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 50,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        $device = Device::create([
            'station_id' => $station->id,
            'package_id' => $package->id,
            'device_code' => 'PS5-01',
            'display_name' => 'PS5-01',
            'device_type' => 'ps5',
            'operational_status' => 'active',
        ]);

        return [$station, $package, $device];
    }
}
