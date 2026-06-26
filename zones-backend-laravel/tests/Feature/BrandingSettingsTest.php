<?php

namespace Tests\Feature;

use App\Models\PlatformSetting;
use App\Models\User;
use App\Support\MediaUrl;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class BrandingSettingsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        Role::findOrCreate('super_admin');
        Role::findOrCreate('manager');
    }

    public function test_public_branding_settings_are_accessible_without_auth(): void
    {
        $this->getJson('/api/public/branding-settings')
            ->assertOk()
            ->assertJsonPath('platform_name', PlatformSetting::DEFAULT_PLATFORM_NAME)
            ->assertJsonPath('logo_url', null);
    }

    public function test_super_admin_can_upload_platform_logo(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $file = UploadedFile::fake()->image('zones-logo.png', 512, 512);

        $response = $this->withToken($token)
            ->postJson('/api/super-admin/branding/logo', [
                'logo' => $file,
            ])
            ->assertOk()
            ->assertJsonPath('branding.platform_name', PlatformSetting::DEFAULT_PLATFORM_NAME);

        $logoUrl = $response->json('branding.logo_url');
        $this->assertIsString($logoUrl);
        $this->assertNotEmpty($logoUrl);

        $settings = PlatformSetting::current();
        $this->assertNotNull($settings->platform_logo_path);
        Storage::disk('public')->assertExists($settings->platform_logo_path);

        $this->getJson('/api/public/branding-settings')
            ->assertOk()
            ->assertJsonPath('logo_url', $logoUrl)
            ->assertJsonPath('platform_name', PlatformSetting::DEFAULT_PLATFORM_NAME);
    }

    public function test_logo_upload_replaces_previous_file(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $first = UploadedFile::fake()->image('first.png');
        $this->withToken($token)
            ->postJson('/api/super-admin/branding/logo', ['logo' => $first])
            ->assertOk();

        $oldPath = PlatformSetting::current()->platform_logo_path;

        $second = UploadedFile::fake()->image('second.png');
        $this->withToken($token)
            ->postJson('/api/super-admin/branding/logo', ['logo' => $second])
            ->assertOk();

        Storage::disk('public')->assertMissing($oldPath);
        Storage::disk('public')->assertExists(PlatformSetting::current()->platform_logo_path);
    }

    public function test_non_super_admin_cannot_upload_platform_logo(): void
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');
        $token = $manager->createToken('test')->plainTextToken;

        $file = UploadedFile::fake()->image('logo.png');

        $this->withToken($token)
            ->postJson('/api/super-admin/branding/logo', ['logo' => $file])
            ->assertForbidden();
    }

    public function test_logo_upload_rejects_invalid_file_types(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $file = UploadedFile::fake()->create('document.pdf', 100, 'application/pdf');

        $this->withToken($token)
            ->postJson('/api/super-admin/branding/logo', ['logo' => $file])
            ->assertUnprocessable();
    }

    public function test_custom_platform_name_is_returned_in_public_payload(): void
    {
        PlatformSetting::current()->update([
            'platform_name' => 'ZONES Gaming',
        ]);

        $this->getJson('/api/public/branding-settings')
            ->assertOk()
            ->assertJsonPath('platform_name', 'ZONES Gaming');
    }

    public function test_branding_payload_uses_media_url_for_stored_logo(): void
    {
        PlatformSetting::current()->update([
            'platform_logo_path' => 'branding/zones_logo_test.png',
        ]);

        Storage::disk('public')->put('branding/zones_logo_test.png', 'fake-image');

        $expected = MediaUrl::resolve('branding/zones_logo_test.png');

        $this->getJson('/api/public/branding-settings')
            ->assertOk()
            ->assertJsonPath('logo_url', $expected);
    }

    public function test_super_admin_can_update_platform_name(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('super_admin');
        $token = $admin->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->patchJson('/api/super-admin/branding/settings', [
                'platform_name' => 'ZONES Pro',
            ])
            ->assertOk()
            ->assertJsonPath('branding.platform_name', 'ZONES Pro');

        $this->assertDatabaseHas('platform_settings', [
            'id' => 1,
            'platform_name' => 'ZONES Pro',
        ]);

        $this->getJson('/api/public/branding-settings')
            ->assertOk()
            ->assertJsonPath('platform_name', 'ZONES Pro');
    }

    public function test_non_super_admin_cannot_update_platform_name(): void
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');
        $token = $manager->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->patchJson('/api/super-admin/branding/settings', [
                'platform_name' => 'Blocked Name',
            ])
            ->assertForbidden();
    }
}
