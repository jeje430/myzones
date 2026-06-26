<?php

namespace Tests\Feature;

use App\Models\PlatformSetting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class LoyaltySettingsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('super_admin');
    }

    public function test_public_loyalty_settings_returns_defaults(): void
    {
        $response = $this->getJson('/api/loyalty/settings');

        $response->assertOk()
            ->assertJsonPath('settings.points_per_completed_session', 10)
            ->assertJsonPath('settings.minimum_points_required', 100)
            ->assertJsonPath('settings.estimated_sessions_required', 10);
    }

    public function test_estimated_sessions_rounds_up(): void
    {
        PlatformSetting::current()->update([
            'loyalty_points_per_session' => 15,
            'loyalty_minimum_points_required' => 100,
        ]);

        $response = $this->getJson('/api/loyalty/settings');

        $response->assertOk()
            ->assertJsonPath('settings.estimated_sessions_required', 7);
    }

    public function test_super_admin_can_update_loyalty_settings(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->putJson('/api/super-admin/settings/loyalty', [
            'points_per_completed_session' => 12,
            'minimum_points_required' => 120,
        ]);

        $response->assertOk()
            ->assertJsonPath('settings.points_per_completed_session', 12)
            ->assertJsonPath('settings.minimum_points_required', 120)
            ->assertJsonPath('settings.estimated_sessions_required', 10);

        $this->assertDatabaseHas('platform_settings', [
            'loyalty_points_per_session' => 12,
            'loyalty_minimum_points_required' => 120,
        ]);
    }

    public function test_non_super_admin_cannot_update_loyalty_settings(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->putJson('/api/super-admin/settings/loyalty', [
            'points_per_completed_session' => 12,
            'minimum_points_required' => 120,
        ]);

        $response->assertForbidden();
    }
}
