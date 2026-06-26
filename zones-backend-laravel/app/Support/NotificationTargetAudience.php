<?php

namespace App\Support;

use InvalidArgumentException;

class NotificationTargetAudience
{
    public const CUSTOMERS_ONLY = 'customers_only';

    public const RECEPTION_ONLY = 'reception_only';

    public const MAINTENANCE_ONLY = 'maintenance_only';

    public const ALL_EMPLOYEES = 'all_employees';

    public const RECEPTION_MAINTENANCE = 'reception_maintenance';

    public const CUSTOMERS_RECEPTION = 'customers_reception';

    public const CUSTOMERS_MAINTENANCE = 'customers_maintenance';

    public const EVERYONE = 'everyone';

  /** @return list<string> */
    public static function all(): array
    {
        return [
            self::CUSTOMERS_ONLY,
            self::RECEPTION_ONLY,
            self::MAINTENANCE_ONLY,
            self::ALL_EMPLOYEES,
            self::RECEPTION_MAINTENANCE,
            self::CUSTOMERS_RECEPTION,
            self::CUSTOMERS_MAINTENANCE,
            self::EVERYONE,
        ];
    }

    public static function isValid(string $value): bool
    {
        return in_array($value, self::all(), true);
    }

    /** @return list<string> */
    public static function selectable(): array
    {
        return [
            self::EVERYONE,
            self::CUSTOMERS_ONLY,
            self::RECEPTION_ONLY,
            self::MAINTENANCE_ONLY,
        ];
    }

    public static function isSelectable(string $value): bool
    {
        return in_array($value, self::selectable(), true);
    }

    /**
     * Accept canonical keys plus legacy UI/API aliases (e.g. "customer", "زبون").
     */
    public static function normalize(string $value): string
    {
        $trimmed = trim($value);
        $lower = strtolower($trimmed);

        $aliases = [
            'customer' => self::CUSTOMERS_ONLY,
            'customers' => self::CUSTOMERS_ONLY,
            'client' => self::CUSTOMERS_ONLY,
            'زبون' => self::CUSTOMERS_ONLY,
            'customers_only' => self::CUSTOMERS_ONLY,
            'reception' => self::RECEPTION_ONLY,
            'reception_only' => self::RECEPTION_ONLY,
            'maintenance' => self::MAINTENANCE_ONLY,
            'maintenance_only' => self::MAINTENANCE_ONLY,
            'employees' => self::ALL_EMPLOYEES,
            'all_employees' => self::ALL_EMPLOYEES,
            'reception_maintenance' => self::RECEPTION_MAINTENANCE,
            'customers_reception' => self::CUSTOMERS_RECEPTION,
            'customers_maintenance' => self::CUSTOMERS_MAINTENANCE,
            'all' => self::EVERYONE,
            'everyone' => self::EVERYONE,
        ];

        if (isset($aliases[$lower])) {
            return $aliases[$lower];
        }

        if (isset($aliases[$trimmed])) {
            return $aliases[$trimmed];
        }

        if (self::isValid($trimmed)) {
            return $trimmed;
        }

        throw new InvalidArgumentException("Invalid notification target audience: {$value}");
    }

    /**
     * Resolve Spatie role names for a target audience key.
     *
     * @return list<string>
     */
    public static function rolesFor(string $targetAudience): array
    {
        if (! self::isValid($targetAudience)) {
            throw new InvalidArgumentException("Invalid notification target audience: {$targetAudience}");
        }

        return match ($targetAudience) {
            self::CUSTOMERS_ONLY => ['customer'],
            self::RECEPTION_ONLY => ['reception'],
            self::MAINTENANCE_ONLY => ['maintenance'],
            self::ALL_EMPLOYEES, self::RECEPTION_MAINTENANCE => ['reception', 'maintenance'],
            self::CUSTOMERS_RECEPTION => ['customer', 'reception'],
            self::CUSTOMERS_MAINTENANCE => ['customer', 'maintenance'],
            self::EVERYONE => ['customer', 'reception', 'maintenance'],
        };
    }

    public static function roleRequiresStation(string $role): bool
    {
        return in_array($role, ['reception', 'maintenance'], true);
    }
}
