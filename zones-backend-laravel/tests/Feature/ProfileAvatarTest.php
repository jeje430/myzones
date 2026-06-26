<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class ProfileAvatarTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        Role::findOrCreate('customer');
        Role::findOrCreate('manager');
    }

    public function test_customer_can_upload_avatar(): void
    {
        $user = User::factory()->create();
        $user->assignRole('customer');
        Sanctum::actingAs($user);

        $file = UploadedFile::fake()->image('avatar.jpg', 200, 200);

        $response = $this->postJson('/api/profile/avatar', [
            'avatar' => $file,
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'message',
                'avatar_url',
                'user' => ['profile_image'],
            ])
            ->assertJson(['success' => true]);

        $url = $response->json('avatar_url');
        $this->assertNotNull($url);
        $this->assertSame($url, $response->json('user.profile_image'));
        $this->assertNotNull($url);
        $this->assertStringContainsString('/storage/avatars/', $url);

        $user->refresh();
        $this->assertNotNull($user->profile_image);
        $this->assertStringStartsWith('avatars/', $user->profile_image);
        Storage::disk('public')->assertExists($user->profile_image);
    }

    public function test_upload_replaces_old_avatar_file(): void
    {
        $user = User::factory()->create(['profile_image' => 'avatars/old.jpg']);
        Storage::disk('public')->put('avatars/old.jpg', 'old-content');
        $user->assignRole('manager');
        Sanctum::actingAs($user);

        $file = UploadedFile::fake()->image('new.png');

        $this->postJson('/api/profile/avatar', ['avatar' => $file])->assertOk();

        Storage::disk('public')->assertMissing('avatars/old.jpg');
        $user->refresh();
        $this->assertNotSame('avatars/old.jpg', $user->profile_image);
    }

    public function test_user_can_delete_avatar(): void
    {
        $user = User::factory()->create(['profile_image' => 'avatars/to-delete.jpg']);
        Storage::disk('public')->put('avatars/to-delete.jpg', 'content');
        $user->assignRole('customer');
        Sanctum::actingAs($user);

        $this->deleteJson('/api/profile/avatar')->assertOk();

        $user->refresh();
        $this->assertNull($user->profile_image);
        Storage::disk('public')->assertMissing('avatars/to-delete.jpg');
    }

    public function test_profile_endpoint_returns_absolute_avatar_url(): void
    {
        $user = User::factory()->create(['profile_image' => 'avatars/profile.jpg']);
        Storage::disk('public')->put('avatars/profile.jpg', 'content');
        $user->assignRole('customer');
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/profile');

        $response->assertOk();
        $url = $response->json('user.profile_image');
        $this->assertStringStartsWith('http', $url);
    }

    public function test_accepts_webp_avatar(): void
    {
        $user = User::factory()->create();
        $user->assignRole('customer');
        Sanctum::actingAs($user);

        $file = UploadedFile::fake()->create('avatar.webp', 100, 'image/webp');

        $this->postJson('/api/profile/avatar', ['avatar' => $file])
            ->assertOk()
            ->assertJson(['success' => true]);

        $user->refresh();
        $this->assertStringEndsWith('.webp', $user->profile_image);
    }

    public function test_rejects_invalid_avatar_type(): void
    {
        $user = User::factory()->create();
        $user->assignRole('customer');
        Sanctum::actingAs($user);

        $file = UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf');

        $this->postJson('/api/profile/avatar', ['avatar' => $file])->assertStatus(422);
    }
}
