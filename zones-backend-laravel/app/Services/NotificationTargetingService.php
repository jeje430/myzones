<?php

namespace App\Services;

use App\Models\CustomerNotification;
use App\Models\DeviceToken;
use App\Models\StaffNotification;
use App\Models\Station;
use App\Models\StationBroadcast;
use App\Models\User;
use App\Support\NotificationTargetAudience;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class NotificationTargetingService
{
    public function __construct(
        private readonly FcmBroadcastService $fcm,
    ) {}

    /**
     * @return array{
     *     recipients: int,
     *     customer_notifications: int,
     *     staff_notifications: int,
     *     fcm_sent: int,
     *     fcm_failed: int,
     *     fcm_skipped: int,
     *     valid_tokens: int,
     *     fcm_reason: string|null
     * }
     */
    public function dispatchBroadcast(StationBroadcast $broadcast): array
    {
        Log::info('broadcast.dispatch.start', [
            'broadcast_id' => $broadcast->id,
            'station_id' => $broadcast->station_id,
            'target_audience' => $broadcast->target_audience,
        ]);

        try {
            $users = $this->resolveRecipients($broadcast->station, $broadcast->target_audience);

            $payload = [
                'broadcast_id' => $broadcast->id,
                'station_id' => $broadcast->station_id,
                'station_name' => $broadcast->station?->name,
                'severity' => $broadcast->severity,
                'target_audience' => $broadcast->target_audience,
                'alternative_instructions' => $broadcast->alternative_instructions,
            ];

            $customerCount = 0;
            $staffCount = 0;

            DB::transaction(function () use ($broadcast, $users, $payload, &$customerCount, &$staffCount) {
                foreach ($users as $user) {
                    if ($user->hasRole('customer')) {
                        CustomerNotification::create([
                            'user_id' => $user->id,
                            'type' => 'manager_broadcast',
                            'title' => $broadcast->name,
                            'body' => $broadcast->body,
                            'payload' => $payload,
                        ]);
                        $customerCount++;
                    }

                    if ($user->hasAnyRole(['reception', 'maintenance', 'manager'])) {
                        StaffNotification::create([
                            'user_id' => $user->id,
                            'station_id' => $broadcast->station_id,
                            'broadcast_id' => $broadcast->id,
                            'type' => 'manager_broadcast',
                            'title' => $broadcast->name,
                            'body' => $broadcast->body,
                            'payload' => $payload,
                        ]);
                        $staffCount++;
                    }
                }
            });

            $userIds = $users->pluck('id');

            $tokenRows = DeviceToken::query()
                ->whereIn('user_id', $userIds)
                ->whereNotNull('token')
                ->where('token', '!=', '')
                ->get(['user_id', 'token']);

            $tokens = $tokenRows
                ->pluck('token')
                ->map(fn ($token) => trim((string) $token))
                ->filter()
                ->unique()
                ->values()
                ->all();

            Log::info('broadcast.dispatch.tokens', [
                'broadcast_id' => $broadcast->id,
                'recipient_user_ids' => $userIds->take(20)->values()->all(),
                'users_with_tokens' => $tokenRows->pluck('user_id')->unique()->count(),
                'valid_token_count' => count($tokens),
                'sample_token_prefixes' => collect($tokens)->take(3)->map(fn ($t) => substr($t, 0, 16))->all(),
            ]);

            $fcmResult = ['sent' => 0, 'failed' => 0, 'skipped' => count($tokens), 'reason' => 'no_tokens'];

            if ($tokens !== []) {
                $fcmResult = $this->fcm->sendToTokens($tokens, $broadcast->name, $broadcast->body, [
                    'type' => 'manager_broadcast',
                    'broadcast_id' => (string) $broadcast->id,
                    'station_id' => (string) $broadcast->station_id,
                    'severity' => $broadcast->severity,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ]);
            }

            Log::info('broadcast.dispatch.complete', [
                'broadcast_id' => $broadcast->id,
                'recipients' => $users->count(),
                'customer_notifications' => $customerCount,
                'staff_notifications' => $staffCount,
                'fcm' => $fcmResult,
            ]);

            return [
                'recipients' => $users->count(),
                'customer_notifications' => $customerCount,
                'staff_notifications' => $staffCount,
                'fcm_sent' => $fcmResult['sent'],
                'fcm_failed' => $fcmResult['failed'],
                'fcm_skipped' => $fcmResult['skipped'],
                'valid_tokens' => count($tokens),
                'fcm_reason' => $fcmResult['reason'] ?? null,
            ];
        } catch (Throwable $e) {
            Log::error('broadcast.dispatch.failed', [
                'broadcast_id' => $broadcast->id,
                'station_id' => $broadcast->station_id,
                'target_audience' => $broadcast->target_audience,
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    /**
     * @return Collection<int, User>
     */
    public function resolveRecipients(Station $station, string $targetAudience): Collection
    {
        $normalizedAudience = NotificationTargetAudience::normalize($targetAudience);
        $roles = NotificationTargetAudience::rolesFor($normalizedAudience);
        $users = collect();

        Log::info('broadcast.resolve_recipients.start', [
            'target_audience' => $targetAudience,
            'normalized_audience' => $normalizedAudience,
            'roles' => $roles,
            'station_id' => $station->id,
        ]);

        foreach ($roles as $role) {
            $query = User::role($role, 'web');

            if (NotificationTargetAudience::roleRequiresStation($role)) {
                $query->where('station_id', $station->id);
            }

            Log::info('broadcast.resolve_recipients.role_query', [
                'role' => $role,
                'sql' => $query->toSql(),
                'bindings' => $query->getBindings(),
                'count' => (clone $query)->count(),
                'sample_user_ids' => (clone $query)->limit(10)->pluck('id')->all(),
            ]);

            $users = $users->merge($query->get());
        }

        $unique = $users->unique('id')->values();

        Log::info('broadcast.resolve_recipients.complete', [
            'target_audience' => $normalizedAudience,
            'total_recipients' => $unique->count(),
            'sample_user_ids' => $unique->take(20)->pluck('id')->all(),
        ]);

        return $unique;
    }
}
