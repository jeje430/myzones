<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\CustomerNotification;
use App\Models\LoyaltyPointTransaction;
use App\Models\PlatformSetting;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class LoyaltyService
{
    public function settings(): PlatformSetting
    {
        return PlatformSetting::current();
    }

    /**
     * @return array<string, mixed>
     */
    public function progressPayload(User $user): array
    {
        $settings = $this->settings();
        $minimum = max(1, (int) $settings->loyalty_minimum_points_required);
        $perSession = max(1, (int) $settings->loyalty_points_per_session);
        $balance = max(0, (int) $user->loyalty_points_balance);
        $estimatedSessions = (int) ceil($minimum / $perSession);
        $sessionsRemaining = $balance >= $minimum
            ? 0
            : (int) ceil(max(0, $minimum - $balance) / $perSession);

        return [
            'points_balance' => $balance,
            'minimum_points_required' => $minimum,
            'points_per_completed_session' => $perSession,
            'estimated_sessions_required' => $estimatedSessions,
            'sessions_remaining' => $sessionsRemaining,
            'progress_points' => min($balance, $minimum),
            'progress_max' => $minimum,
            'progress_percent' => min(100, (int) round(($balance / $minimum) * 100)),
            'can_redeem_reward' => $balance >= $minimum,
            'reward_unlocked' => $balance >= $minimum,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function statusPayload(User $user): array
    {
        $notifications = CustomerNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->orderByDesc('id')
            ->limit(20)
            ->get()
            ->map(fn (CustomerNotification $n) => [
                'id' => $n->id,
                'type' => $n->type,
                'title' => $n->title,
                'body' => $n->body,
                'payload' => $n->payload,
                'created_at' => $n->created_at?->toIso8601String(),
            ])
            ->values()
            ->all();

        return [
            'loyalty' => $this->progressPayload($user),
            'notifications' => $notifications,
        ];
    }

    public function canRedeemReward(User $user): bool
    {
        $minimum = max(1, (int) $this->settings()->loyalty_minimum_points_required);

        return (int) $user->loyalty_points_balance >= $minimum;
    }

    /**
     * @return array{deducted: int, balance_after: int}
     */
    public function redeemForBooking(User $user, Booking $booking): array
    {
        $settings = $this->settings();
        $minimum = max(1, (int) $settings->loyalty_minimum_points_required);
        $perSession = max(1, (int) $settings->loyalty_points_per_session);

        return DB::transaction(function () use ($user, $booking, $minimum, $perSession) {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->firstOrFail();
            $balance = (int) $lockedUser->loyalty_points_balance;

            if ($balance < $minimum) {
                throw ValidationException::withMessages([
                    'payment_method' => ["رصيد النقاط غير كافٍ. تحتاج {$minimum} نقطة على الأقل."],
                ]);
            }

            $balanceAfter = $balance - $minimum;
            $lockedUser->update(['loyalty_points_balance' => $balanceAfter]);

            LoyaltyPointTransaction::create([
                'user_id' => $lockedUser->id,
                'booking_id' => $booking->id,
                'type' => LoyaltyPointTransaction::TYPE_REDEEM,
                'points' => -$minimum,
                'balance_after' => $balanceAfter,
                'note' => "استبدال مكافأة ولاء — حجز {$booking->booking_number}",
            ]);

            $booking->update([
                'loyalty_points_redeemed' => $minimum,
                'loyalty_points_per_session' => $perSession,
                'loyalty_points_total' => $minimum,
                'loyalty_coupon_label' => 'مكافأة ولاء',
                'loyalty_coupon_code' => 'LOYALTY-REWARD',
            ]);

            return [
                'deducted' => $minimum,
                'balance_after' => $balanceAfter,
            ];
        });
    }

    /**
     * @return array{earned: int, balance_after: int}|null
     */
    public function awardForCompletedSession(Booking $booking): ?array
    {
        if ($booking->loyalty_points_awarded_at) {
            return null;
        }

        if ($this->isLoyaltyRewardBooking($booking)) {
            return null;
        }

        $user = $this->resolveUserForBooking($booking);
        if (! $user) {
            return null;
        }

        $settings = $this->settings();
        $points = max(1, (int) $settings->loyalty_points_per_session);

        return DB::transaction(function () use ($booking, $user, $points) {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->firstOrFail();
            $previousBalance = (int) $lockedUser->loyalty_points_balance;
            $balanceAfter = $previousBalance + $points;

            $lockedUser->update(['loyalty_points_balance' => $balanceAfter]);

            LoyaltyPointTransaction::create([
                'user_id' => $lockedUser->id,
                'booking_id' => $booking->id,
                'type' => LoyaltyPointTransaction::TYPE_EARN,
                'points' => $points,
                'balance_after' => $balanceAfter,
                'note' => "إتمام جلسة — +{$points} نقطة",
            ]);

            $booking->update(['loyalty_points_awarded_at' => now()]);

            $minimum = max(1, (int) $this->settings()->loyalty_minimum_points_required);
            if ($previousBalance < $minimum && $balanceAfter >= $minimum) {
                $this->createRewardUnlockedNotification($lockedUser);
            }

            return [
                'earned' => $points,
                'balance_after' => $balanceAfter,
            ];
        });
    }

    public function markNotificationRead(User $user, CustomerNotification $notification): void
    {
        if ((int) $notification->user_id !== (int) $user->id) {
            abort(403);
        }

        if (! $notification->read_at) {
            $notification->update(['read_at' => now()]);
        }
    }

    public function isLoyaltyRewardBooking(Booking $booking): bool
    {
        return $booking->payment_method === 'loyalty_reward'
            || $booking->booking_type === 'loyalty';
    }

    private function createRewardUnlockedNotification(User $user): CustomerNotification
    {
        $minimum = max(1, (int) $this->settings()->loyalty_minimum_points_required);

        return CustomerNotification::create([
            'user_id' => $user->id,
            'type' => 'loyalty_reward_unlocked',
            'title' => 'مكافأة الولاء متاحة!',
            'body' => "لقد فتحت حجزاً مجانياً بمكافأة الولاء! رصيدك {$minimum} نقطة — يمكنك الحجز الآن.",
        ]);
    }

    private function resolveUserForBooking(Booking $booking): ?User
    {
        if ($booking->user_id) {
            return User::query()->find($booking->user_id);
        }

        $phone = trim((string) $booking->visitor_phone);
        if ($phone === '') {
            return null;
        }

        $normalized = preg_replace('/\D+/', '', $phone) ?: '';

        return User::query()
            ->where(function ($query) use ($phone, $normalized) {
                $query->where('phone', $phone);
                if ($normalized !== '') {
                    $query->orWhereRaw("REPLACE(REPLACE(REPLACE(phone, '+', ''), ' ', ''), '-', '') LIKE ?", ["%{$normalized}"]);
                }
            })
            ->first();
    }
}
