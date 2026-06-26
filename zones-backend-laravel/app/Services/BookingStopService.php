<?php

namespace App\Services;

use App\Models\Station;
use App\Models\StationBookingStop;
use App\Support\BookingStopReason;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

class BookingStopService
{
    /**
     * Auto-close stops whose end date has passed.
     */
    public function expireStaleStops(?int $stationId = null): int
    {
        $today = now()->toDateString();

        $query = StationBookingStop::query()
            ->active()
            ->whereNotNull('ends_on')
            ->whereDate('ends_on', '<', $today);

        if ($stationId !== null) {
            $query->where('station_id', $stationId);
        }

        return $query->update([
            'status' => 'ended',
            'ended_at' => now(),
        ]);
    }

    public function activeForStation(Station $station, ?Carbon $onDate = null): ?StationBookingStop
    {
        $this->expireStaleStops($station->id);

        $date = ($onDate ?? now())->toDateString();

        return StationBookingStop::query()
            ->where('station_id', $station->id)
            ->active()
            ->whereDate('starts_on', '<=', $date)
            ->where(function ($q) use ($date) {
                $q->whereNull('ends_on')
                    ->orWhereDate('ends_on', '>=', $date);
            })
            ->orderByDesc('starts_on')
            ->first();
    }

    public function isDateBlocked(Station $station, string $dateYmd): bool
    {
        return $this->activeForStation($station, Carbon::parse($dateYmd)) !== null;
    }

    public function isBookingBlockedNow(Station $station): bool
    {
        return $this->activeForStation($station) !== null;
    }

    public function blockMessage(StationBookingStop $stop): string
    {
        $reason = BookingStopReason::label($stop->reason_key);

        if ($stop->ends_on === null) {
            return "الحجوزات متوقفة مؤقتاً بسبب {$reason} حتى إشعار آخر";
        }

        $until = $stop->ends_on->format('Y-m-d');

        return "الحجز متوقف مؤقتاً بسبب {$reason} حتى {$until}";
    }

    public function customerButtonLabel(): string
    {
        return 'الحجز غير متاح مؤقتاً';
    }

    /**
     * @return array<string, mixed>|null
     */
    public function publicPayload(?StationBookingStop $stop): ?array
    {
        if ($stop === null) {
            return null;
        }

        return [
            'id' => $stop->id,
            'active' => true,
            'reason_key' => $stop->reason_key,
            'reason_label' => BookingStopReason::label($stop->reason_key),
            'starts_on' => $stop->starts_on?->format('Y-m-d'),
            'ends_on' => $stop->ends_on?->format('Y-m-d'),
            'message' => $this->blockMessage($stop),
            'button_label' => $this->customerButtonLabel(),
            'open_ended' => $stop->ends_on === null,
        ];
    }

    /**
     * @return Collection<int, StationBookingStop>
     */
    public function listForStation(int $stationId): Collection
    {
        $this->expireStaleStops($stationId);

        return StationBookingStop::query()
            ->where('station_id', $stationId)
            ->orderByDesc('created_at')
            ->get();
    }

    public function create(
        Station $station,
        int $createdBy,
        string $reasonKey,
        string $startsOn,
        ?string $endsOn = null,
    ): StationBookingStop {
        if (! BookingStopReason::isValid($reasonKey)) {
            throw ValidationException::withMessages([
                'reason_key' => ['سبب الإيقاف غير صالح'],
            ]);
        }

        if ($this->activeForStation($station) !== null) {
            throw ValidationException::withMessages([
                'booking_stop' => ['يوجد إيقاف حجوزات نشط بالفعل'],
            ]);
        }

        if ($endsOn !== null && $endsOn < $startsOn) {
            throw ValidationException::withMessages([
                'ends_on' => ['تاريخ النهاية يجب أن يكون بعد تاريخ البداية'],
            ]);
        }

        return StationBookingStop::create([
            'station_id' => $station->id,
            'reason_key' => $reasonKey,
            'starts_on' => $startsOn,
            'ends_on' => $endsOn,
            'status' => 'active',
            'created_by' => $createdBy,
        ]);
    }

    public function update(
        StationBookingStop $stop,
        string $reasonKey,
        ?string $endsOn,
    ): StationBookingStop {
        if ($stop->status !== 'active') {
            throw ValidationException::withMessages([
                'booking_stop' => ['لا يمكن تعديل سجل منتهٍ'],
            ]);
        }

        if (! BookingStopReason::isValid($reasonKey)) {
            throw ValidationException::withMessages([
                'reason_key' => ['سبب الإيقاف غير صالح'],
            ]);
        }

        if ($endsOn !== null && $endsOn < $stop->starts_on->format('Y-m-d')) {
            throw ValidationException::withMessages([
                'ends_on' => ['تاريخ النهاية يجب أن يكون بعد تاريخ البداية'],
            ]);
        }

        $stop->update([
            'reason_key' => $reasonKey,
            'ends_on' => $endsOn,
        ]);

        return $stop->fresh();
    }

    public function resume(StationBookingStop $stop): StationBookingStop
    {
        if ($stop->status !== 'active') {
            throw ValidationException::withMessages([
                'booking_stop' => ['الإيقاف غير نشط'],
            ]);
        }

        $stop->update([
            'status' => 'ended',
            'ended_at' => now(),
        ]);

        return $stop->fresh();
    }

    public function delete(StationBookingStop $stop): void
    {
        $stop->delete();
    }
}
