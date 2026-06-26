<?php

namespace Tests\Feature;

use App\Models\Package;
use App\Models\Station;
use App\Models\StationComment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class StationCommentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer');
        Role::findOrCreate('manager');
    }

    public function test_customer_can_submit_and_edit_comment(): void
    {
        [$station, $customer] = $this->createPublishedLoungeFixture();
        Sanctum::actingAs($customer);

        $create = $this->postJson("/api/lounges/{$station->id}/comments", [
            'body' => 'تجربة رائعة',
        ]);

        $create->assertCreated()
            ->assertJsonPath('comment.body', 'تجربة رائعة')
            ->assertJsonPath('comment.customer_name', $customer->full_name);

        $commentId = $create->json('comment.id');

        $update = $this->putJson("/api/lounges/{$station->id}/comments/{$commentId}", [
            'body' => 'تجربة ممتازة ومحدّثة',
        ]);

        $update->assertOk()
            ->assertJsonPath('comment.body', 'تجربة ممتازة ومحدّثة');

        $this->assertDatabaseHas('station_comments', [
            'id' => $commentId,
            'body' => 'تجربة ممتازة ومحدّثة',
        ]);
    }

    public function test_manager_can_reply_to_comment(): void
    {
        [$station, $customer, $manager] = $this->createPublishedLoungeFixture(withManager: true);

        $comment = StationComment::create([
            'station_id' => $station->id,
            'user_id' => $customer->id,
            'body' => 'هل لديكم عروض؟',
        ]);

        Sanctum::actingAs($manager);

        $response = $this->postJson("/api/manager/comments/{$comment->id}/reply", [
            'body' => 'نعم، لدينا عروض أسبوعية',
        ]);

        $response->assertOk()
            ->assertJsonPath('comment.manager_reply.body', 'نعم، لدينا عروض أسبوعية');

        $this->assertEquals(1, StationComment::query()->where('parent_id', $comment->id)->count());
    }

    public function test_manager_comments_include_absolute_profile_image(): void
    {
        [$station, $customer, $manager] = $this->createPublishedLoungeFixture(withManager: true);

        $customer->update(['profile_image' => 'avatars/test-customer.jpg']);
        \Illuminate\Support\Facades\Storage::disk('public')->put('avatars/test-customer.jpg', 'avatar');

        StationComment::create([
            'station_id' => $station->id,
            'user_id' => $customer->id,
            'body' => 'تعليق مع صورة',
        ]);

        Sanctum::actingAs($manager);

        $response = $this->getJson('/api/manager/comments');

        $response->assertOk()
            ->assertJsonPath('comments.0.customer_name', $customer->full_name)
            ->assertJsonStructure([
                'comments' => [
                    [
                        'profile_image',
                        'user' => ['id', 'name', 'profile_image'],
                    ],
                ],
            ]);

        $url = $response->json('comments.0.profile_image');
        $this->assertNotNull($url);
        $this->assertStringStartsWith('http', $url);
        $this->assertStringContainsString('/storage/avatars/', $url);
    }

    public function test_authenticated_author_sees_can_edit_on_list(): void
    {
        [$station, $customer] = $this->createPublishedLoungeFixture();

        StationComment::create([
            'station_id' => $station->id,
            'user_id' => $customer->id,
            'body' => 'تعليقي الخاص',
        ]);

        Sanctum::actingAs($customer);

        $response = $this->getJson("/api/lounges/{$station->id}/comments");

        $response->assertOk()
            ->assertJsonPath('comments.0.can_edit', true);
    }

    public function test_guest_cannot_see_can_edit_on_list(): void
    {
        [$station, $customer] = $this->createPublishedLoungeFixture();

        StationComment::create([
            'station_id' => $station->id,
            'user_id' => $customer->id,
            'body' => 'تعليق عام',
        ]);

        $response = $this->getJson("/api/lounges/{$station->id}/comments");

        $response->assertOk()
            ->assertJsonPath('comments.0.can_edit', false);
    }

    public function test_public_can_list_comments(): void
    {
        [$station, $customer] = $this->createPublishedLoungeFixture();

        StationComment::create([
            'station_id' => $station->id,
            'user_id' => $customer->id,
            'body' => 'صالة جميلة',
        ]);

        $response = $this->getJson("/api/lounges/{$station->id}/comments");

        $response->assertOk()
            ->assertJsonPath('comments.0.body', 'صالة جميلة')
            ->assertJsonPath('meta.total', 1);
    }

    /**
     * @return array{0: Station, 1: User, 2?: User}
     */
    private function createPublishedLoungeFixture(bool $withManager = false): array
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

        Package::create([
            'station_id' => $station->id,
            'name' => 'PS5 Standard',
            'slug' => 'ps5-'.$station->id,
            'package_type' => 'ps5',
            'hourly_price' => 50,
            'minimum_hours' => 1,
            'is_active' => true,
        ]);

        $customer = User::factory()->create(['full_name' => 'أحمد محمد']);
        $customer->assignRole('customer');

        if ($withManager) {
            $manager->update(['station_id' => $station->id]);

            return [$station, $customer, $manager];
        }

        return [$station, $customer];
    }
}
