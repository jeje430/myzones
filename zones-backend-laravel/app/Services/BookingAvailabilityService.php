<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Device;
use App\Models\Offer;
use App\Models\Package;
use App\Models\Station;
use App\Support\BookingStatus;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class BookingAvailabilityService
{
    public function __construct(
        private readonly BookingStopService $bookingStops,
    ) {}

    /**
     * @return array{available: bool, message: ?string, slots: list<array<string, mixed>>}
     */
    public function slotsForPackage(
        Station $station,
        Package $package,
        string $date,
        ?Offer $offer = null,
    ): array {
        if ($offer && ! $this->isDateInOfferWindow($offer, $date)) {
            return [
                'available' => false,
                'message' => 'التاريخ خارج فترة العرض',
                'slots' => [],
            ];
        }

        if (! $station->bookings_enabled) {
            return [
                'available' => false,
                'message' => 'الحجز غير متاح لهذه الصالة حالياً',
                'slots' => [],
            ];
        }

        if ($this->bookingStops->isDateBlocked($station, $date)) {
            $active = $this->bookingStops->activeForStation($station, \Carbon\Carbon::parse($date));

            return [
                'available' => false,
                'message' => $active ? $this->bookingStops->blockMessage($active) : 'الحجز غير متاح مؤقتاً',
                'slots' => [],
                'booking_stop' => $this->bookingStops->publicPayload($active),
            ];
        }

        if (! $this->isWorkingDay($station, $date)) {
            return [
                'available' => false,
                'message' => 'لا يوجد حجز متاح',
                'slots' => [],
            ];
        }

        $devices = Device::query()
            ->where('station_id', $station->id)
            ->where('package_id', $package->id)
            ->where('operational_status', 'active')
            ->orderBy('device_code')
            ->get();

        if ($devices->isEmpty()) {
            return [
                'available' => false,
                'message' => 'لا يوجد حجز متاح',
                'slots' => [],
            ];
        }

        $hours = $this->workHoursForDate($station, $date);
        if ($hours->isEmpty()) {
            return [
                'available' => false,
                'message' => 'لا يوجد حجز متاح',
                'slots' => [],
            ];
        }

        $bookings = $this->activeBookingsForDate($station->id, $date);
        $duration = max(1, (int) ($package->minimum_hours ?? 1));
        $hourlyPrice = (float) $package->hourly_price;
        $originalHourly = $offer ? (float) $offer->original_price : $hourlyPrice;
        $discountedHourly = $offer ? (float) $offer->discounted_price : $hourlyPrice;
        $discountPercent = $offer ? (int) ($offer->discount_percent ?? 0) : 0;

        $slots = [];
        foreach ($hours as $hour) {
            $device = $this->firstAvailableDevice($devices, $bookings, $date, $hour, $duration);
            if (! $device) {
                continue;
            }

            $hourTo = $this->calcHourTo($hour, $duration);
            $start = Carbon::parse("$date $hour", config('app.timezone', 'Africa/Tripoli'));
            $end = Carbon::parse("$date $hourTo", config('app.timezone', 'Africa/Tripoli'));
            if ($end->lte($start)) {
                $end->addDay();
            }

            $originalTotal = round($originalHourly * $duration, 2);
            $discountedTotal = round($discountedHourly * $duration, 2);

            $slots[] = [
                'id' => "{$package->id}-{$date}-{$hour}-{$device->id}",
                'hour' => $hour,
                'hour_to' => $hourTo,
                'label' => $this->slotLabel($hour, $hourTo),
                'device_id' => $device->id,
                'device_code' => $device->device_code,
                'device_name' => $device->display_name ?: $device->device_code,
                'package_id' => $package->id,
                'package_name' => $package->name,
                'hourly_price' => $originalHourly,
                'hours_count' => $duration,
                'original_total_price' => $originalTotal,
                'discount_percent' => $discountPercent,
                'total_price' => $discountedTotal,
                'is_available' => true,
                'starts_at' => $start->toIso8601String(),
                'ends_at' => $end->toIso8601String(),
            ];
        }

        if ($slots === []) {
            return [
                'available' => false,
                'message' => 'لا يوجد حجز متاح',
                'slots' => [],
            ];
        }

        return [
            'available' => true,
            'message' => null,
            'slots' => $slots,
        ];
    }

    public function deviceIsAvailable(
        int $stationId,
        int $deviceId,
        string $date,
        string $hour,
        int $durationHours = 1,
        ?int $ignoreBookingId = null,
    ): bool {
        $hourTo = $this->calcHourTo($hour, $durationHours);
        $bookings = $this->activeBookingsForDate($stationId, $date)
            ->where('device_id', $deviceId);

        if ($ignoreBookingId) {
            $bookings = $bookings->where('id', '!=', $ignoreBookingId);
        }

        return ! $this->hasOverlap($bookings, $date, $hour, $hourTo);
    }

    /**
     * @return Collection<int, Booking>
     */
    public function activeBookingsForDate(int $stationId, string $date): Collection
    {
        return Booking::query()
            ->where('station_id', $stationId)
            ->whereDate('start_date', '<=', $date)
            ->whereDate('end_date', '>=', $date)
            ->whereNotIn('booking_status', BookingStatus::inactiveStatuses())
            ->get();
    }

    /**
     * @return Collection<int, string>
     */
    public function workHoursForDate(Station $station, string $date): Collection
    {
        $opens = $this->normalizeHour((string) $station->opens_at ?: '14:00');
        $closes = $this->normalizeHour((string) $station->closes_at ?: '02:00');

        $openH = (int) explode(':', $opens)[0];
        $closeH = (int) explode(':', $closes)[0];

        $hours = collect();
        if ($opens <= $closes) {
            for ($h = $openH; $h < $closeH; $h++) {
                $hours->push(sprintf('%02d:00', $h));
            }
        } else {
            for ($h = $openH; $h < 24; $h++) {
                $hours->push(sprintf('%02d:00', $h));
            }
            for ($h = 0; $h < $closeH; $h++) {
                $hours->push(sprintf('%02d:00', $h));
            }
        }

        $today = Carbon::now(config('app.timezone', 'Africa/Tripoli'))->format('Y-m-d');
        if ($date === $today) {
            $currentHour = (int) Carbon::now(config('app.timezone', 'Africa/Tripoli'))->format('H');
            $hours = $hours->filter(function (string $hour) use ($currentHour) {
                return (int) explode(':', $hour)[0] > $currentHour;
            });
        }

        return $hours->values();
    }

    public function normalizeHour(string $time): string
    {
        $parts = explode(':', $time);
        $h = (int) ($parts[0] ?? 0);

        return sprintf('%02d:00', $h % 24);
    }

    public function calcHourTo(string $hour, int $durationHours = 1): string
    {
        $startH = (int) explode(':', $hour)[0];
        $endH = ($startH + max(1, $durationHours)) % 24;

        return sprintf('%02d:00', $endH);
    }

    public function hourSpan(string $hour, string $hourTo): int
    {
        $startH = (int) explode(':', $hour)[0];
        $endH = (int) explode(':', $hourTo)[0];

        if ($endH <= $startH) {
            return max(1, $endH + 24 - $startH);
        }

        return max(1, $endH - $startH);
    }

    private function isWorkingDay(Station $station, string $date): bool
    {
        $days = $station->working_days;
        if (! is_array($days) || $days === []) {
            return true;
        }

        $dayIndex = Carbon::parse($date)->dayOfWeek;

        return in_array($dayIndex, $days, true) || in_array((string) $dayIndex, $days, true);
    }

    /**
     * @param  Collection<int, Device>  $devices
     * @param  Collection<int, Booking>  $bookings
     */
    private function firstAvailableDevice(
        Collection $devices,
        Collection $bookings,
        string $date,
        string $hour,
        int $duration,
    ): ?Device {
        $hourTo = $this->calcHourTo($hour, $duration);
        $deviceBookings = $bookings->groupBy('device_id');

        foreach ($devices as $device) {
            $deviceRows = $deviceBookings->get($device->id, collect());
            if (! $this->hasOverlap($deviceRows, $date, $hour, $hourTo)) {
                return $device;
            }
        }

        return null;
    }

    /**
     * @param  Collection<int, Booking>  $bookings
     */
    private function hasOverlap(Collection $bookings, string $date, string $hour, string $hourTo): bool
    {
        $slotStart = $this->hourToMinutes($hour);
        $slotEnd = $this->hourToMinutes($hourTo);
        if ($slotEnd <= $slotStart) {
            $slotEnd += 24 * 60;
        }

        foreach ($bookings as $booking) {
            $start = $this->hourToMinutes($this->normalizeHour((string) $booking->start_time));
            $end = $this->hourToMinutes($this->normalizeHour((string) $booking->end_time));
            if ($end <= $start) {
                $end += 24 * 60;
            }

            if ($slotStart < $end && $slotEnd > $start) {
                return true;
            }
        }

        return false;
    }

    private function hourToMinutes(string $hour): int
    {
        $parts = explode(':', $hour);

        return ((int) ($parts[0] ?? 0)) * 60;
    }

    private function slotLabel(string $hour, string $hourTo): string
    {
        return $this->formatHourArabic($hour).' → '.$this->formatHourArabic($hourTo);
    }

    private function formatHourArabic(string $hour): string
    {
        $h = (int) explode(':', $hour)[0];
        if ($h == 0) {
            return '12 صباحاً';
        }
        if ($h < 12) {
            return "$h صباحاً";
        }
        if ($h == 12) {
            return '12 مساءً';
        }

        return ($h - 12).' مساءً';
    }

    public function isDateInOfferWindow(Offer $offer, string $date): bool
    {
        $day = Carbon::parse($date)->startOfDay();
        $start = $offer->valid_from?->copy()->startOfDay();
        $end = $offer->expires_at?->copy()->startOfDay();

        if (! $start || ! $end) {
            return false;
        }

        return $day->gte($start) && $day->lte($end);
    }
}
