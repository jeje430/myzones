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

class PlatformCommissionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('super_admin');
        Role::findOrCreate('customer');
        Role::findOrCreate('reception');

        PlatformSetting::current()->update(['platform_commission_rate' => 10]);
    }

    public function test_super_admin_can_update_global_commission_rate(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->putJson('/api/super-admin/settings/commission', [
                'platform_commission_rate' => 15,
            ])
            ->assertOk()
            ->assertJsonPath('settings.platform_commission_rate', 15);

        $this->assertDatabaseHas('platform_settings', [
            'platform_commission_rate' => 15,
        ]);
    }

    public function test_mobile_app_booking_stores_platform_commission(): void
    {
        [$station, $customer] = $this->createCustomerFixture();
        $token = $customer->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/bookings', [
            'station_id' => $station->id,
            'package_id' => Package::first()->id,
            'device_id' => Device::first()->id,
            'date' => now()->format('Y-m-d'),
            'hour' => '14:00',
            'payment_method' => 'cash',
        ])->assertCreated();

        $bookingId = $response->json('booking.id');

        $this->assertDatabaseHas('bookings', [
            'id' => $bookingId,
            'booking_source' => 'mobile_app',
            'total_price' => 50,
            'platform_commission_rate' => 10,
            'platform_commission_amount' => 5,
        ]);
    }

    public function test_reception_booking_has_zero_commission(): void
    {
        [$station, $reception] = $this->createReceptionFixture();
        $token = $reception->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/staff/reception/calendar', [
            'package_id' => Package::first()->id,
            'device_id' => Device::first()->id,
            'date' => now()->format('Y-m-d'),
            'hour' => '15:00',
            'visitor_name' => 'زائر',
            'visitor_phone' => '0912345678',
        ])->assertCreated();

        $this->assertDatabaseHas('bookings', [
            'station_id' => $station->id,
            'booking_source' => 'dashboard',
            'platform_commission_amount' => 0,
            'platform_commission_rate' => 0,
        ]);
    }

    public function test_manager_revenue_uses_hall_net_after_commission(): void
    {
        [$station, $manager] = $this->createManagerFixture();

        Booking::create([
            'station_id' => $station->id,
            'device_id' => Device::first()->id,
            'package_id' => Package::first()->id,
            'booking_number' => 'APP-001',
            'booking_type' => 'regular',
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->format('Y-m-d'),
            'start_time' => '12:00',
            'end_time' => '13:00',
            'hours_count' => 1,
            'original_hourly_price' => 100,
            'discounted_hourly_price' => 100,
            'subtotal_price' => 100,
            'platform_commission_rate' => 10,
            'platform_commission_amount' => 10,
            'total_price' => 100,
            'payment_method' => 'cash',
            'payment_status' => 'paid',
            'booking_status' => 'confirmed',
            'session_status' => 'checked_in',
            'is_checked_in' => true,
            'checked_in_at' => now(),
            'booking_source' => 'mobile_app',
        ]);

        $response = $this->withToken($manager->createToken('test')->plainTextToken)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(90.0, (float) $response->json('summary.revenue'));
        $this->assertEquals(10.0, (float) $response->json('summary.platform_commission'));
    }

    public function test_commission_summary_returns_platform_totals(): void
    {
        [$station] = $this->createManagerFixture();

        Booking::create([
            'station_id' => $station->id,
            'device_id' => Device::first()->id,
            'package_id' => Package::first()->id,
            'booking_number' => 'APP-002',
            'booking_type' => 'offer',
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->format('Y-m-d'),
            'start_time' => '16:00',
            'end_time' => '17:00',
            'hours_count' => 1,
            'original_hourly_price' => 80,
            'discounted_hourly_price' => 60,
            'subtotal_price' => 80,
            'platform_commission_rate' => 10,
            'platform_commission_amount' => 6,
            'total_price' => 60,
            'payment_method' => 'cash',
            'payment_status' => 'paid',
            'booking_status' => 'confirmed',
            'session_status' => 'checked_in',
            'is_checked_in' => true,
            'checked_in_at' => now(),
            'booking_source' => 'mobile_app',
        ]);

        $admin = User::factory()->create();
        $admin->assignRole('super_admin');

        $response = $this->withToken($admin->createToken('test')->plainTextToken)
            ->getJson('/api/super-admin/finance/commissions?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(6.0, (float) $response->json('total_commissions'));
        $this->assertEquals(60.0, (float) $response->json('total_app_gross_revenue'));
        $this->assertEquals(1, (int) $response->json('total_app_bookings'));
    }

  /**
     * @return array{0: Station, 1: User}
     */
    private function createManagerFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');
        $station = $this->createStation($manager);
        $manager->update(['station_id' => $station->id]);

        return [$station, $manager];
    }

    /**
     * @return array{0: Station, 1: User}
     */
    private function createCustomerFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');
        $station = $this->createStation($manager);

        $customer = User::factory()->create();
        $customer->assignRole('customer');

        return [$station, $customer];
    }

    /**
     * @return array{0: Station, 1: User}
     */
    private function createReceptionFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');
        $station = $this->createStation($manager);

        $reception = User::factory()->create(['station_id' => $station->id]);
        $reception->assignRole('reception');

        return [$station, $reception];
    }

    private function createStation(User $manager): Station
    {
        $station = Station::create([
            'name' => 'Commission Lounge',
            'slug' => 'commission-lounge',
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
            'manager_id' => $manager->id,
        ]);

        Package::create([
            'station_id' => $station->id,
            'name' => 'Standard',
            'slug' => 'standard-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 50,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        Device::create([
            'station_id' => $station->id,
            'package_id' => Package::first()->id,
            'device_code' => 'PS5-01',
            'display_name' => 'PS5-01',
            'device_type' => 'ps5',
            'operational_status' => 'active',
        ]);

        return $station;
    }
}
