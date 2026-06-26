<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Device;
use App\Models\HallExpense;
use App\Models\Package;
use App\Models\PaymentTransaction;
use App\Models\Station;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class FinancialReportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('reception');
        Role::findOrCreate('maintenance');
    }

    public function test_cash_check_in_marks_booking_paid_for_revenue(): void
    {
        [$station, $reception] = $this->createReceptionFixture();
        $booking = $this->createCashBooking($station, pending: true);

        $this->withToken($reception->createToken('test')->plainTextToken)
            ->postJson("/api/staff/reception/calendar/{$booking->id}/check-in")
            ->assertOk();

        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'payment_status' => 'paid',
            'is_checked_in' => true,
        ]);
    }

    public function test_cash_pending_booking_is_excluded_from_revenue_until_check_in(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $pending = $this->createCashBooking($station, pending: true, total: 50);
        $paid = $this->createCashBooking($station, pending: false, checkedIn: true, total: 75);

        $token = $manager->createToken('test')->plainTextToken;

        $response = $this->withToken($token)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(75.0, (float) $response->json('summary.revenue'));

        $this->assertSame(75.0, (float) $paid->total_price);
        $this->assertSame(50.0, (float) $pending->total_price);
    }

    public function test_loyalty_booking_is_excluded_from_revenue(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $this->createCashBooking($station, pending: false, checkedIn: true, total: 80);

        Booking::create([
            'station_id' => $station->id,
            'device_id' => Device::first()->id,
            'package_id' => Package::first()->id,
            'booking_number' => 'LOY-001',
            'booking_type' => 'loyalty',
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->format('Y-m-d'),
            'start_time' => '16:00',
            'end_time' => '17:00',
            'hours_count' => 1,
            'original_hourly_price' => 50,
            'discounted_hourly_price' => 0,
            'subtotal_price' => 50,
            'total_price' => 0,
            'payment_method' => 'loyalty_reward',
            'payment_status' => 'paid',
            'booking_status' => 'confirmed',
            'session_status' => 'waiting',
            'booking_source' => 'mobile_app',
        ]);

        $response = $this->withToken($manager->createToken('test')->plainTextToken)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(80.0, (float) $response->json('summary.revenue'));
    }

    public function test_online_paid_booking_counts_on_payment_date(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $booking = Booking::create([
            'station_id' => $station->id,
            'device_id' => Device::first()->id,
            'package_id' => Package::first()->id,
            'booking_number' => 'ONL-001',
            'booking_type' => 'regular',
            'start_date' => now()->format('Y-m-d'),
            'end_date' => now()->format('Y-m-d'),
            'start_time' => '18:00',
            'end_time' => '19:00',
            'hours_count' => 1,
            'original_hourly_price' => 60,
            'discounted_hourly_price' => 60,
            'subtotal_price' => 60,
            'total_price' => 60,
            'payment_method' => 'online',
            'payment_status' => 'paid',
            'booking_status' => 'confirmed',
            'session_status' => 'waiting',
            'booking_source' => 'mobile_app',
        ]);

        PaymentTransaction::create([
            'invoice_no' => 'INV-001',
            'user_id' => User::factory()->create()->id,
            'booking_id' => $booking->id,
            'amount' => 60,
            'currency' => 'LYD',
            'gateway' => 'plutu',
            'status' => 'paid',
            'paid_at' => now(),
        ]);

        $response = $this->withToken($manager->createToken('test')->plainTextToken)
            ->getJson('/api/manager/finance/revenue/today')
            ->assertOk();

        $this->assertEquals(60.0, (float) $response->json('today_total'));
    }

    public function test_manager_can_crud_expenses(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $token = $manager->createToken('test')->plainTextToken;

        $create = $this->withToken($token)->postJson('/api/manager/expenses', [
            'name' => 'إيجار',
            'amount' => 500,
            'is_paid' => true,
            'added_at' => now()->format('Y-m-d'),
            'notes' => 'شهري',
        ]);

        $create->assertCreated()
            ->assertJsonPath('expense.name', 'إيجار');

        $expenseId = $create->json('expense.id');

        $update = $this->withToken($token)
            ->putJson("/api/manager/expenses/{$expenseId}", [
                'name' => 'إيجار محدّث',
                'amount' => 550,
                'is_paid' => true,
                'added_at' => now()->format('Y-m-d'),
            ])
            ->assertOk();

        $this->assertEquals(550.0, (float) $update->json('expense.amount'));

        $summary = $this->withToken($token)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(550.0, (float) $summary->json('summary.expenses'));
        $this->assertEquals(-550.0, (float) $summary->json('summary.net_profit'));

        $this->withToken($token)
            ->deleteJson("/api/manager/expenses/{$expenseId}")
            ->assertOk();

        $this->assertDatabaseMissing('hall_expenses', ['id' => $expenseId]);
    }

    public function test_unpaid_expense_is_excluded_from_financial_totals(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $token = $manager->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/manager/expenses', [
            'name' => 'غير مدفوع',
            'amount' => 100,
            'is_paid' => false,
            'added_at' => now()->format('Y-m-d'),
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/manager/expenses', [
            'name' => 'مدفوع',
            'amount' => 200,
            'is_paid' => true,
            'added_at' => now()->format('Y-m-d'),
        ])->assertCreated();

        $summary = $this->withToken($token)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(200.0, (float) $summary->json('summary.expenses'));
    }

    public function test_expense_counts_when_marked_paid(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $token = $manager->createToken('test')->plainTextToken;

        $create = $this->withToken($token)->postJson('/api/manager/expenses', [
            'name' => 'مؤجل',
            'amount' => 150,
            'is_paid' => false,
            'added_at' => now()->format('Y-m-d'),
        ])->assertCreated();

        $expenseId = $create->json('expense.id');

        $before = $this->withToken($token)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(0.0, (float) $before->json('summary.expenses'));

        $this->withToken($token)
            ->putJson("/api/manager/expenses/{$expenseId}", [
                'name' => 'مؤجل',
                'amount' => 150,
                'is_paid' => true,
                'added_at' => now()->format('Y-m-d'),
                'paid_at' => now()->format('Y-m-d'),
            ])
            ->assertOk();

        $after = $this->withToken($token)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(150.0, (float) $after->json('summary.expenses'));
    }

    public function test_maintenance_resolve_creates_unpaid_expense(): void
    {
        [$station, $manager] = $this->createManagerFixture();

        $device = Device::first();
        $fault = \App\Models\DeviceFault::create([
            'station_id' => $station->id,
            'device_id' => $device->id,
            'reported_by' => $manager->id,
            'fault_type' => 'screen',
            'status' => 'in_progress',
            'maintenance_employee_name' => 'فني الصيانة',
            'reported_at' => now(),
        ]);

        $token = $manager->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->postJson("/api/staff/maintenance/faults/{$fault->id}/resolve", [
                'maintenance_cost' => 75,
            ])
            ->assertOk();

        $this->assertDatabaseHas('hall_expenses', [
            'station_id' => $station->id,
            'category' => 'maintenance',
            'device_fault_id' => $fault->id,
            'amount' => 75,
            'is_paid' => false,
        ]);

        $summary = $this->withToken($token)
            ->getJson('/api/manager/finance/summary?year='.now()->year.'&month='.now()->month)
            ->assertOk();

        $this->assertEquals(0.0, (float) $summary->json('summary.expenses'));
    }

    public function test_package_usage_breakdown_uses_completed_sessions_only(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $token = $manager->createToken('test')->plainTextToken;

        $standard = Package::first();
        $vip = Package::create([
            'station_id' => $station->id,
            'name' => 'VIP Package',
            'slug' => 'vip-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 80,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        $this->createCompletedSession($station, $standard->id, now());
        $this->createCompletedSession($station, $standard->id, now());
        $this->createCompletedSession($station, $vip->id, now());

        $this->createCashBooking($station, pending: false, checkedIn: true);

        $response = $this->withToken($token)
            ->getJson('/api/manager/finance/overview?year='.now()->year.'&month='.now()->month.'&package_period=monthly')
            ->assertOk();

        $this->assertArrayNotHasKey('highlights', $response->json());
        $this->assertEquals(3, (int) $response->json('package_usage.total_sessions'));
        $this->assertEquals('monthly', $response->json('package_usage.period'));

        $breakdown = collect($response->json('package_usage.breakdown'))->keyBy('name');
        $this->assertEquals(2, $breakdown->get('Standard')['sessions_count']);
        $this->assertEquals(66.7, (float) $breakdown->get('Standard')['percentage']);
        $this->assertEquals(1, $breakdown->get('VIP Package')['sessions_count']);
        $this->assertEquals(33.3, (float) $breakdown->get('VIP Package')['percentage']);
    }

    public function test_package_usage_respects_daily_period_filter(): void
    {
        [$station, $manager] = $this->createManagerFixture();
        $token = $manager->createToken('test')->plainTextToken;
        $packageId = Package::first()->id;

        $this->createCompletedSession($station, $packageId, now());
        $this->createCompletedSession($station, $packageId, now()->subDay());

        $response = $this->withToken($token)
            ->getJson('/api/manager/finance/overview?year='.now()->year.'&month='.now()->month.'&package_period=daily')
            ->assertOk();

        $this->assertEquals(1, (int) $response->json('package_usage.total_sessions'));
    }

    /**
     * @return array{0: Station, 1: User}
     */
    private function createManagerFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $station = $this->createStation($manager);

        return [$station, $manager];
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
            'name' => 'Finance Lounge',
            'slug' => 'finance-lounge',
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

    private function createCashBooking(
        Station $station,
        bool $pending = true,
        bool $checkedIn = false,
        float $total = 75,
    ): Booking {
        return Booking::create([
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
            'original_hourly_price' => $total,
            'discounted_hourly_price' => $total,
            'subtotal_price' => $total,
            'total_price' => $total,
            'payment_method' => 'cash',
            'payment_status' => $pending ? 'pending' : 'paid',
            'booking_status' => 'confirmed',
            'session_status' => $checkedIn ? 'checked_in' : 'waiting',
            'is_checked_in' => $checkedIn,
            'checked_in_at' => $checkedIn ? now() : null,
            'booking_source' => 'mobile_app',
        ]);
    }

    private function createCompletedSession(Station $station, int $packageId, $endedAt): Booking
    {
        return Booking::create([
            'station_id' => $station->id,
            'device_id' => Device::first()->id,
            'package_id' => $packageId,
            'booking_number' => 'SES-'.uniqid(),
            'booking_type' => 'regular',
            'start_date' => $endedAt->format('Y-m-d'),
            'end_date' => $endedAt->format('Y-m-d'),
            'start_time' => '12:00',
            'end_time' => '13:00',
            'hours_count' => 1,
            'original_hourly_price' => 50,
            'discounted_hourly_price' => 50,
            'subtotal_price' => 50,
            'total_price' => 50,
            'payment_method' => 'cash',
            'payment_status' => 'paid',
            'booking_status' => 'completed',
            'session_status' => 'finished',
            'is_checked_in' => true,
            'checked_in_at' => $endedAt->copy()->subHour(),
            'session_started_at' => $endedAt->copy()->subHour(),
            'session_ended_at' => $endedAt,
            'session_duration_seconds' => 3600,
            'booking_source' => 'mobile_app',
        ]);
    }
}
