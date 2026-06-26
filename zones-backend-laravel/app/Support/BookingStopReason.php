<?php

namespace App\Support;

class BookingStopReason
{
    public const POWER_OUTAGE = 'power_outage';

    public const BAD_WEATHER = 'bad_weather';

    public const HALL_MAINTENANCE = 'hall_maintenance';

    public const ROAD_MAINTENANCE = 'road_maintenance';

    public const INTERNET_OUTAGE = 'internet_outage';

    public const TECHNICAL_ISSUE = 'technical_issue';

    public const EMERGENCY_CLOSURE = 'emergency_closure';

    public const STAFF_SHORTAGE = 'staff_shortage';

    public const SAFETY_ISSUE = 'safety_issue';

    /**
     * @return array<string, string>
     */
    public static function labels(): array
    {
        return [
            self::POWER_OUTAGE => 'انقطاع التيار',
            self::BAD_WEATHER => 'ظروف جوية سيئة',
            self::HALL_MAINTENANCE => 'صيانة الصالة',
            self::ROAD_MAINTENANCE => 'صيانة الطريق',
            self::INTERNET_OUTAGE => 'انقطاع الإنترنت',
            self::TECHNICAL_ISSUE => 'خلل تقني',
            self::EMERGENCY_CLOSURE => 'إغلاق طارئ',
            self::STAFF_SHORTAGE => 'نقص في الموظفين',
            self::SAFETY_ISSUE => 'مشكلة أمنية',
        ];
    }

    /**
     * @return list<array{value: string, label: string}>
     */
    public static function selectable(): array
    {
        return array_map(
            fn (string $key, string $label) => ['value' => $key, 'label' => $label],
            array_keys(self::labels()),
            array_values(self::labels()),
        );
    }

    public static function isValid(string $key): bool
    {
        return array_key_exists($key, self::labels());
    }

    public static function label(string $key): string
    {
        return self::labels()[$key] ?? $key;
    }
}
