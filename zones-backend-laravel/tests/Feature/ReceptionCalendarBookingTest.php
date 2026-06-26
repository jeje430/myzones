<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Device;
use App\Models\Package;
use App\Models\Station;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class ReceptionCalendarBookingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('reception');
    }

    public function test_reception_can_create_manual_pay_on_arrival_booking(): void
    {
        [$station, $reception, $device, $package] = $this->createReceptionFixture();
        $token = $reception->createToken('test')->plainTextToken;
        $date = now()->addDay()->format('Y-m-d');

        $response = $this->withToken($token)->postJson('/api/staff/reception/calendar', [
            'device_id' => $device->id,
            'date' => $date,
            'hour' => '18:00',
            'visitor_name' => 'أحمد محمد',
            'visitor_phone' => '0912345678',
            'notes' => 'حجز من الاستقبال',
        ]);

        $response->assertCreated()
            ->assertJsonPath('slot.status', 'reserved')
            ->assertJsonPath('slot.source', 'manual')
            ->assertJsonPath('slot.visitorName', 'أحمد محمد')
            ->assertJsonPath('slot.paymentType', 'cash');

        $booking = Booking::query()->first();
        $this->assertNotNull($booking);
        $this->assertSame('cash', $booking->payment_method);
        $this->assertSame('pending', $booking->payment_status);
        $this->assertSame('confirmed', $booking->booking_status);
        $this->assertSame('dashboard', $booking->booking_source);
        $this->assertNotNull($booking->receipt_pdf_path);
    }

    public function test_reception_booking_rejects_overlapping_slot(): void
    {
        [$station, $reception, $device, $package] = $this->createReceptionFixture();
        $token = $reception->createToken('test')->plainTextToken;
        $date = now()->addDay()->format('Y-m-d');

        Booking::create([
            'station_id' => $station->id,
            'device_id' => $device->id,
            'package_id' => $package->id,
            'booking_number' => 'BK-001',
            'booking_type' => 'regular',
            'start_date' => $date,
            'end_date' => $date,
            'start_time' => '18:00',
            'end_time' => '19:00',
            'hours_count' => 1,
            'original_hourly_price' => 25,
            'discounted_hourly_price' => 25,
            'subtotal_price' => 25,
            'total_price' => 25,
            'payment_method' => 'cash',
            'payment_status' => 'pending',
            'booking_status' => 'confirmed',
            'session_status' => 'waiting',
            'booking_source' => 'dashboard',
        ]);

        $response = $this->withToken($token)->postJson('/api/staff/reception/calendar', [
            'device_id' => $device->id,
            'date' => $date,
            'hour' => '18:00',
            'visitor_name' => 'زبون آخر',
            'visitor_phone' => '0999999999',
        ]);

        $response->assertStatus(422);
    }

    /**
     * @return array{0: Station, 1: User, 2: Device, 3: Package}
     */
    private function createReceptionFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $station = Station::create([
            'name' => 'Reception Lounge',
            'slug' => 'reception-lounge-'.uniqid(),
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
            'manager_id' => $manager->id,
        ]);

        $manager->update(['station_id' => $station->id]);

        $reception = User::factory()->create(['station_id' => $station->id]);
        $reception->assignRole('reception');

        $package = Package::create([
            'station_id' => $station->id,
            'name' => 'PS5 Standard',
            'slug' => 'ps5-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 25,
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

        return [$station, $reception, $device, $package];
    }
}
