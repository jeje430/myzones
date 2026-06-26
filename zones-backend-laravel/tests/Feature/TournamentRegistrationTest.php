<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\Package;
use App\Models\Station;
use App\Models\Tournament;
use App\Models\TournamentParticipant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class TournamentRegistrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer');
        Role::findOrCreate('manager');
    }

    public function test_manager_can_create_tournament_with_registration_deadline(): void
    {
        [$manager, $station, $token] = $this->createManagerFixture();

        $response = $this->withToken($token)->postJson('/api/manager/tournaments', [
            'title' => 'Summer Cup',
            'game_name' => 'FC 25',
            'max_participants' => 16,
            'prize_summary' => '500 L.D.',
            'start_date' => now()->addDays(7)->toDateString(),
            'end_date' => now()->addDays(8)->toDateString(),
            'registration_deadline' => now()->addDays(5)->toIso8601String(),
            'delay_minutes' => 10,
            'withdrawal_rule' => 'خسارة',
            'match_rules' => "• يجب أن يكون لكل مباراة فائز.\n• لا يُسمح بالتعادل.",
        ]);

        $response->assertCreated()
            ->assertJsonPath('tournament.title', 'Summer Cup')
            ->assertJsonPath('tournament.max_participants', 16)
            ->assertJsonPath('tournament.participants_count', 0);

        $this->assertDatabaseHas('tournaments', [
            'station_id' => $station->id,
            'title' => 'Summer Cup',
            'max_participants' => 16,
        ]);
    }

    public function test_manager_can_set_registration_deadline_on_start_day_with_time(): void
    {
        [$manager, $station, $token] = $this->createManagerFixture();
        unset($manager, $station);

        $start = now()->addDays(7)->startOfDay();

        $response = $this->withToken($token)->postJson('/api/manager/tournaments', [
            'title' => 'Night Cup',
            'game_name' => 'FC 25',
            'max_participants' => 8,
            'prize_summary' => '300 L.D.',
            'start_date' => $start->toDateString(),
            'end_date' => $start->copy()->addDay()->toDateString(),
            'registration_deadline' => $start->copy()->setTime(22, 0)->toIso8601String(),
            'delay_minutes' => 10,
            'withdrawal_rule' => 'خسارة',
            'match_rules' => "• rules",
        ]);

        $response->assertCreated()
            ->assertJsonPath('tournament.is_registration_open', true)
            ->assertJsonPath('tournament.can_join', true);
    }

    public function test_customer_can_register_and_unregister_before_deadline(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        $tournament = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Weekend Cup',
            'game_name' => 'Tekken 8',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => now()->addDay(),
            'prize_summary' => '200 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 16,
            'is_active' => true,
        ]);

        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        $register = $this->withToken($token)->postJson("/api/tournaments/{$tournament->id}/register", [
            'player_name' => 'Player One',
        ]);

        $register->assertCreated()
            ->assertJsonPath('tournament.participants_count', 1)
            ->assertJsonPath('tournament.my_registration_status', 'registered');

        $this->assertDatabaseHas('tournament_participants', [
            'tournament_id' => $tournament->id,
            'user_id' => $customer->id,
            'status' => 'registered',
        ]);

        $unregister = $this->withToken($token)->postJson("/api/tournaments/{$tournament->id}/unregister");

        $unregister->assertOk()
            ->assertJsonPath('tournament.participants_count', 0);

        $this->assertDatabaseHas('tournament_participants', [
            'tournament_id' => $tournament->id,
            'user_id' => $customer->id,
            'status' => 'withdrawn',
        ]);
    }

    public function test_registration_blocked_when_tournament_is_full(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        $tournament = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Full Cup',
            'game_name' => 'FIFA',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => now()->addDay(),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 2,
            'is_active' => true,
        ]);

        foreach (range(1, 2) as $i) {
            $user = User::factory()->create();
            TournamentParticipant::create([
                'tournament_id' => $tournament->id,
                'user_id' => $user->id,
                'name' => "Player {$i}",
                'status' => 'registered',
                'registered_at' => now(),
            ]);
        }

        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson("/api/tournaments/{$tournament->id}/register");

        $response->assertStatus(422)
            ->assertJsonPath('message', 'اكتمل عدد المشاركين في هذه البطولة');
    }

    public function test_unregister_blocked_after_registration_deadline(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        $tournament = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Closed Cup',
            'game_name' => 'COD',
            'start_date' => now()->addDay(),
            'end_date' => now()->addDays(2),
            'registration_deadline' => now()->subHour(),
            'prize_summary' => '50 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        TournamentParticipant::create([
            'tournament_id' => $tournament->id,
            'user_id' => $customer->id,
            'name' => $customer->full_name ?? $customer->name ?? 'Customer',
            'status' => 'registered',
            'registered_at' => now()->subDay(),
        ]);

        $response = $this->withToken($token)->postJson("/api/tournaments/{$tournament->id}/unregister");

        $response->assertStatus(422)
            ->assertJsonPath('message', 'انتهى موعد الانسحاب من هذه البطولة');
    }

    public function test_my_registrations_lists_registered_and_withdrawn(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        $tournament = Tournament::create([
            'station_id' => $station->id,
            'title' => 'History Cup',
            'game_name' => 'MK1',
            'start_date' => now()->addDays(5),
            'end_date' => now()->addDays(6),
            'registration_deadline' => now()->addDays(2),
            'prize_summary' => '300 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        TournamentParticipant::create([
            'tournament_id' => $tournament->id,
            'user_id' => $customer->id,
            'name' => $customer->full_name ?? $customer->name ?? 'Customer',
            'status' => 'withdrawn',
            'registered_at' => now()->subDay(),
            'withdrawn_at' => now(),
        ]);

        $response = $this->withToken($token)->getJson('/api/tournaments/my/registrations');

        $response->assertOk()
            ->assertJsonPath('registrations.0.tournament_title', 'History Cup')
            ->assertJsonPath('registrations.0.status', 'withdrawn')
            ->assertJsonPath('registrations.0.status_label', 'منسحب');
    }

    public function test_active_registrations_excludes_completed_tournaments(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        $active = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Active Cup',
            'game_name' => 'FIFA',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => now()->addDay(),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $completed = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Done Cup',
            'game_name' => 'COD',
            'start_date' => now()->subDays(3),
            'end_date' => now()->subDay(),
            'registration_deadline' => now()->subDays(5),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'completed',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        foreach ([$active, $completed] as $tournament) {
            TournamentParticipant::create([
                'tournament_id' => $tournament->id,
                'user_id' => $customer->id,
                'name' => 'Player',
                'status' => 'registered',
                'registered_at' => now(),
            ]);
        }

        $response = $this->withToken($token)->getJson('/api/tournaments/my/registrations/active');

        $response->assertOk()
            ->assertJsonCount(1, 'registrations')
            ->assertJsonPath('registrations.0.tournament_title', 'Active Cup')
            ->assertJsonPath('registrations.0.can_withdraw', true)
            ->assertJsonPath('registrations.0.participants_count', 1)
            ->assertJsonPath('registrations.0.max_participants', 8);
    }

    public function test_participation_history_lists_only_completed_tournaments(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        $completed = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Finished Cup',
            'game_name' => 'Tekken',
            'start_date' => now()->subDays(5),
            'end_date' => now()->subDay(),
            'registration_deadline' => now()->subDays(6),
            'prize_summary' => '200 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'completed',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $upcoming = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Future Cup',
            'game_name' => 'FIFA',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => now()->addDay(),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        foreach ([$completed, $upcoming] as $tournament) {
            TournamentParticipant::create([
                'tournament_id' => $tournament->id,
                'user_id' => $customer->id,
                'name' => 'Player',
                'status' => 'registered',
                'registered_at' => now(),
            ]);
        }

        $response = $this->withToken($token)->getJson('/api/tournaments/my/registrations/history');

        $response->assertOk()
            ->assertJsonCount(1, 'registrations')
            ->assertJsonPath('registrations.0.tournament_title', 'Finished Cup')
            ->assertJsonPath('registrations.0.completion_status', 'مكتملة')
            ->assertJsonPath('registrations.0.lounge_name', 'Manager Lounge');
    }

    public function test_customer_can_fetch_tournament_bracket_after_participating(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        $tournament = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Bracket Cup',
            'game_name' => 'FIFA',
            'start_date' => now()->subDay(),
            'end_date' => now()->addDay(),
            'registration_deadline' => now()->subDays(2),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'completed',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $customer = User::factory()->create();
        $customer->assignRole('customer');
        $token = $customer->createToken('test')->plainTextToken;

        TournamentParticipant::create([
            'tournament_id' => $tournament->id,
            'user_id' => $customer->id,
            'name' => 'Player',
            'status' => 'registered',
            'registered_at' => now()->subDays(3),
        ]);

        $response = $this->withToken($token)->getJson("/api/tournaments/{$tournament->id}/bracket");

        $response->assertOk()
            ->assertJsonPath('tournament.title', 'Bracket Cup')
            ->assertJsonPath('tournament.status', 'completed');
    }

    public function test_manager_can_cancel_tournament(): void
    {
        [$manager, $station, $token] = $this->createManagerFixture();

        $tournament = Tournament::create([
            'station_id' => $station->id,
            'title' => 'Cancel Me',
            'game_name' => 'FIFA',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => now()->addDay(),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $cancel = $this->withToken($token)->postJson("/api/manager/tournaments/{$tournament->id}/cancel");
        $cancel->assertOk()->assertJsonPath('tournament.status', 'cancelled');

        $public = $this->getJson('/api/tournaments');
        $titles = collect($public->json())->pluck('title')->all();
        $this->assertNotContains('Cancel Me', $titles);
    }

    public function test_public_index_hides_legacy_demo_tournaments_without_deadline(): void
    {
        [$manager, $station] = $this->createManagerFixture();
        unset($manager);

        Tournament::create([
            'station_id' => $station->id,
            'title' => 'Valorant Pro League',
            'game_name' => 'Valorant',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => null,
            'prize_summary' => '600 د.ل + ميداليات',
            'entry_fee' => 0,
            'match_rules' => '• demo',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 16,
            'is_active' => true,
        ]);

        Tournament::create([
            'station_id' => $station->id,
            'title' => 'Manager Cup',
            'game_name' => 'FIFA',
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'registration_deadline' => now()->addDay(),
            'prize_summary' => '100 L.D.',
            'entry_fee' => 0,
            'match_rules' => '• rules',
            'delay_minutes' => 10,
            'status' => 'upcoming',
            'max_participants' => 8,
            'is_active' => true,
        ]);

        $response = $this->getJson('/api/tournaments');

        $response->assertOk();
        $titles = collect($response->json())->pluck('title')->all();
        $this->assertContains('Manager Cup', $titles);
        $this->assertNotContains('Valorant Pro League', $titles);
    }

    /**
     * @return array{0: User, 1: Station, 2: string}
     */
    private function createManagerFixture(): array
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $station = Station::create([
            'name' => 'Manager Lounge',
            'slug' => 'manager-lounge',
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
            'package_id' => Package::where('station_id', $station->id)->value('id'),
            'device_code' => 'PS5-01',
            'display_name' => 'PS5-01',
            'device_type' => 'ps5',
            'operational_status' => 'active',
        ]);

        $token = $manager->createToken('test')->plainTextToken;

        return [$manager, $station, $token];
    }
}
