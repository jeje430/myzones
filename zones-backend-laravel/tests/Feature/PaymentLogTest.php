<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Device;
use App\Models\Package;
use App\Models\Payment;
use App\Models\PaymentTransaction;
use App\Models\Station;
use App\Models\User;
use App\Services\PaymentLogService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class PaymentLogTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('reception');
    }

    public function test_electronic_payment_is_logged_on_gateway_verification(): void
    {
        [$station, $user, $booking] = $this->createBookingFixture(paymentMethod: 'online');

        $transaction = PaymentTransaction::create([
            'invoice_no' => 'BK-TEST-001',
            'user_id' => $user->id,
            'booking_id' => $booking->id,
            'amount' => 40,
            'currency' => 'LYD',
            'gateway' => 'plutu_local_bank',
            'status' => 'paid',
            'paid_at' => now(),
        ]);

        $payment = app(PaymentLogService::class)->logElectronicPayment($transaction);

        $this->assertNotNull($payment);
        $this->assertDatabaseHas('payments', [
            'booking_id' => $booking->id,
            'payment_method' => 'electronic',
            'status' => 'completed',
            'transaction_ref' => 'BK-TEST-001',
        ]);
    }

    public function test_electronic_payment_is_not_duplicated(): void
    {
        [$station, $user, $booking] = $this->createBookingFixture(paymentMethod: 'online');

        $transaction = PaymentTransaction::create([
            'invoice_no' => 'BK-TEST-002',
            'user_id' => $user->id,
            'booking_id' => $booking->id,
            'amount' => 25,
            'currency' => 'LYD',
            'gateway' => 'plutu_local_bank',
            'status' => 'paid',
            'paid_at' => now(),
        ]);

        $service = app(PaymentLogService::class);
        $first = $service->logElectronicPayment($transaction);
        $second = $service->logElectronicPayment($transaction);

        $this->assertEquals($first->id, $second->id);
        $this->assertSame(1, Payment::query()->count());
    }

    public function test_cash_booking_does_not_log_payment_at_creation(): void
    {
        [$station, $user, $booking] = $this->createBookingFixture(
            paymentMethod: 'cash',
            paymentStatus: 'pending',
        );

        $payment = app(PaymentLogService::class)->logPayOnArrivalPayment($booking);

        $this->assertNull($payment);
        $this->assertDatabaseCount('payments', 0);
    }

    public function test_pay_on_arrival_payment_is_logged_only_at_check_in(): void
    {
        [$station, $reception, $booking] = $this->createReceptionBookingFixture();

        $this->withToken($reception->createToken('test')->plainTextToken)
            ->postJson("/api/staff/reception/calendar/{$booking->id}/check-in")
            ->assertOk();

        $this->assertDatabaseHas('payments', [
            'booking_id' => $booking->id,
            'payment_method' => 'pay_on_arrival',
            'status' => 'completed',
        ]);

        $this->assertSame(1, Payment::query()->where('booking_id', $booking->id)->count());
    }

    public function test_manager_can_list_payments_with_filter(): void
    {
        [$station, $customer, $onlineBooking] = $this->createBookingFixture(paymentMethod: 'online');
        $manager = User::query()->find($station->manager_id);

        Payment::create([
            'booking_id' => $onlineBooking->id,
            'user_id' => $customer->id,
            'amount' => 40,
            'payment_method' => 'electronic',
            'transaction_ref' => 'INV-ONLINE',
            'status' => 'completed',
            'paid_at' => now()->subHour(),
        ]);

        [$cashStation, $cashCustomer, $cashBooking] = $this->createBookingFixture(
            paymentMethod: 'cash',
            paymentStatus: 'paid',
            checkedIn: true,
        );

        Payment::create([
            'booking_id' => $cashBooking->id,
            'user_id' => $cashCustomer->id,
            'amount' => 75,
            'payment_method' => 'pay_on_arrival',
            'transaction_ref' => $cashBooking->booking_number,
            'status' => 'completed',
            'paid_at' => now(),
        ]);

        $token = $manager->createToken('test')->plainTextToken;

        $all = $this->withToken($token)
            ->getJson('/api/manager/finance/payments')
            ->assertOk();

        $this->assertCount(1, $all->json('payments'));

        $electronic = $this->withToken($token)
            ->getJson('/api/manager/finance/payments?payment_method=electronic')
            ->assertOk();

        $this->assertCount(1, $electronic->json('payments'));
        $this->assertSame('electronic', $electronic->json('payments.0.payment_method'));
    }

    public function test_payments_default_to_today_and_support_date_filter(): void
    {
        [$station, $customer, $onlineBooking] = $this->createBookingFixture(paymentMethod: 'online');
        $manager = User::query()->find($station->manager_id);
        $token = $manager->createToken('test')->plainTextToken;

        Payment::create([
            'booking_id' => $onlineBooking->id,
            'user_id' => $customer->id,
            'amount' => 40,
            'payment_method' => 'electronic',
            'transaction_ref' => 'INV-TODAY',
            'status' => 'completed',
            'paid_at' => now(),
        ]);

        $yesterdayBooking = Booking::create([
            'station_id' => $station->id,
            'user_id' => $customer->id,
            'device_id' => Device::first()->id,
            'package_id' => Package::first()->id,
            'booking_number' => 'APP-YDAY',
            'booking_type' => 'regular',
            'start_date' => now()->subDay()->format('Y-m-d'),
            'end_date' => now()->subDay()->format('Y-m-d'),
            'start_time' => '12:00',
            'end_time' => '13:00',
            'hours_count' => 1,
            'original_hourly_price' => 25,
            'discounted_hourly_price' => 25,
            'subtotal_price' => 25,
            'total_price' => 25,
            'payment_method' => 'online',
            'payment_status' => 'paid',
            'booking_status' => 'confirmed',
            'session_status' => 'waiting',
            'booking_source' => 'mobile_app',
        ]);

        Payment::create([
            'booking_id' => $yesterdayBooking->id,
            'user_id' => $customer->id,
            'amount' => 25,
            'payment_method' => 'electronic',
            'transaction_ref' => 'INV-YDAY',
            'status' => 'completed',
            'paid_at' => now()->subDay(),
        ]);

        $today = $this->withToken($token)
            ->getJson('/api/manager/finance/payments')
            ->assertOk();

        $this->assertCount(1, $today->json('payments'));
        $this->assertSame(now()->toDateString(), $today->json('filter.date'));

        $yesterday = $this->withToken($token)
            ->getJson('/api/manager/finance/payments?date='.now()->subDay()->toDateString())
            ->assertOk();

        $this->assertCount(1, $yesterday->json('payments'));
        $this->assertSame('INV-YDAY', $yesterday->json('payments.0.transaction_ref'));

        $all = $this->withToken($token)
            ->getJson('/api/manager/finance/payments?show_all=1')
            ->assertOk();

        $this->assertCount(2, $all->json('payments'));
        $this->assertTrue($all->json('filter.show_all'));
    }

    /**
     * @return array{0: Station, 1: User, 2: Booking}
     */
    private function createBookingFixture(
        string $paymentMethod = 'online',
        string $paymentStatus = 'paid',
        bool $checkedIn = false,
    ): array {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $station = $this->createStation($manager);
        $customer = User::factory()->create();

        $booking = Booking::create([
            'station_id' => $station->id,
            'user_id' => $customer->id,
            'device_id' => Device::first()->id,
            'package_id' => Package::first()->id,
            'booking_number' => 'APP-'.uniqid(),
            'booking_type' => 'regular',
            'visitor_name' => 'Test Visitor',
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->format('Y-m-d'),
            'start_time' => '12:00',
            'end_time' => '13:00',
            'hours_count' => 1,
            'original_hourly_price' => 40,
            'discounted_hourly_price' => 40,
            'subtotal_price' => 40,
            'total_price' => 40,
            'payment_method' => $paymentMethod,
            'payment_status' => $paymentStatus,
            'booking_status' => 'confirmed',
            'session_status' => $checkedIn ? 'checked_in' : 'waiting',
            'is_checked_in' => $checkedIn,
            'checked_in_at' => $checkedIn ? now() : null,
            'booking_source' => 'mobile_app',
        ]);

        return [$station, $customer, $booking];
    }

    /**
     * @return array{0: Station, 1: User, 2: Booking}
     */
    private function createReceptionBookingFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $station = $this->createStation($manager);

        $reception = User::factory()->create(['station_id' => $station->id]);
        $reception->assignRole('reception');

        $booking = Booking::create([
            'station_id' => $station->id,
            'device_id' => Device::first()->id,
            'package_id' => Package::first()->id,
            'booking_number' => 'CASH-'.uniqid(),
            'booking_type' => 'regular',
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->format('Y-m-d'),
            'start_time' => '12:00',
            'end_time' => '13:00',
            'hours_count' => 1,
            'original_hourly_price' => 75,
            'discounted_hourly_price' => 75,
            'subtotal_price' => 75,
            'total_price' => 75,
            'payment_method' => 'cash',
            'payment_status' => 'pending',
            'booking_status' => 'confirmed',
            'session_status' => 'waiting',
            'is_checked_in' => false,
            'booking_source' => 'mobile_app',
        ]);

        return [$station, $reception, $booking];
    }

    private function createStation(User $manager): Station
    {
        $station = Station::create([
            'name' => 'Payments Lounge',
            'slug' => 'payments-lounge-'.uniqid(),
            'is_active' => true,
            'is_published' => true,
            'bookings_enabled' => true,
            'manager_id' => $manager->id,
        ]);

        $manager->update(['station_id' => $station->id]);

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
