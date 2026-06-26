<?php

namespace App\Support;

class WorkShiftSchedule
{
    /** @var array<string, string> */
    public const HOURS = [
        'morning' => 'من 2 مساءً إلى 8 مساءً',
        'evening' => 'من 8 مساءً إلى 2 صباحاً',
    ];

    /** @var array<string, string> */
    public const PERIOD_LABELS = [
        'morning' => 'الفترة الأولى',
        'evening' => 'الفترة الثانية',
    ];

    public static function workingHours(?string $shift): ?string
    {
        if ($shift === null || $shift === '') {
            return null;
        }

        return self::HOURS[$shift] ?? null;
    }

    public static function periodLabel(?string $shift): ?string
    {
        if ($shift === null || $shift === '') {
            return null;
        }

        return self::PERIOD_LABELS[$shift] ?? null;
    }

    public static function displayHours(?string $shift): string
    {
        return self::workingHours($shift) ?? 'غير محدد';
    }
}
