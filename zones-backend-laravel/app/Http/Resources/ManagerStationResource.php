<?php

namespace App\Http\Resources;

use App\Models\Station;
use App\Support\MediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ManagerStationResource extends JsonResource
{
    /** @var Station */
    public $resource;

    private const SERVICE_LABELS = [
        'ps5' => ['label' => 'PlayStation 5', 'shortLabel' => 'PS5'],
        'xbox' => ['label' => 'Xbox', 'shortLabel' => 'XBOX'],
        'vr' => ['label' => 'VR', 'shortLabel' => 'VR'],
        'vip' => ['label' => 'VIP', 'shortLabel' => 'VIP'],
        'simulator' => ['label' => 'Simulator', 'shortLabel' => 'SIMULATOR'],
        'racing' => ['label' => 'Racing', 'shortLabel' => 'RACING'],
        'pc' => ['label' => 'PC Gaming', 'shortLabel' => 'PC'],
        'free_wifi' => ['label' => 'إنترنت مجاني', 'shortLabel' => 'Free WiFi'],
        'snacks' => ['label' => 'سناكس', 'shortLabel' => 'سناكس'],
        'cafeteria' => ['label' => 'كافتيريا', 'shortLabel' => 'كافتيريا'],
    ];

    public function toArray(Request $request): array
    {
        $station = $this->resource;

        if ($this->isBlankProfile($station)) {
            return $this->blankProfilePayload($station);
        }

        $services = $this->formatServices($station->available_services ?? []);
        $displayName = $this->displayHallName($station);

        return [
            'id' => $station->id,
            'station_id' => $station->id,
            'hall_id' => $station->id,
            'hallName' => $displayName,
            'name' => $displayName,
            'description' => $station->description ?? '',
            'city' => $station->city ?? '',
            'address' => $station->address ?? '',
            'mapLink' => $station->map_link ?? '',
            'latitude' => $station->latitude !== null ? (string) $station->latitude : '',
            'longitude' => $station->longitude !== null ? (string) $station->longitude : '',
            'phone' => $station->phone ?? '',
            'email' => $station->email ?? '',
            'workHoursFrom' => $this->formatTimeForInput($station->opens_at) ?? '14:00',
            'workHoursTo' => $this->formatTimeForInput($station->closes_at) ?? '02:00',
            'image' => MediaUrl::resolve($station->cover_image) ?? '',
            'cover_image' => $station->cover_image,
            'image_url' => MediaUrl::resolve($station->cover_image) ?? '',
            'status' => $station->is_published ? 'active' : 'pending',
            'published' => (bool) $station->is_published,
            'is_published' => (bool) $station->is_published,
            'setup_completed' => (bool) $station->is_published,
            'published_at' => $station->published_at?->toIso8601String(),
            'available_services' => array_keys($services),
            'services' => $services,
            'servicesAvailability' => $this->servicesAvailabilityMap($station->available_services ?? []),
        ];
    }

    private function isBlankProfile(Station $station): bool
    {
        return ! $station->is_published && preg_match('/^صالة #\d+$/u', (string) $station->name);
    }

    /**
     * @return array<string, mixed>
     */
    private function blankProfilePayload(Station $station): array
    {
        return [
            'id' => $station->id,
            'station_id' => $station->id,
            'hall_id' => $station->id,
            'hallName' => '',
            'name' => '',
            'description' => '',
            'city' => '',
            'address' => '',
            'mapLink' => '',
            'latitude' => '',
            'longitude' => '',
            'phone' => '',
            'email' => $station->email ?? '',
            'workHoursFrom' => '14:00',
            'workHoursTo' => '02:00',
            'image' => '',
            'cover_image' => null,
            'image_url' => '',
            'status' => 'pending',
            'published' => false,
            'available_services' => [],
            'services' => [],
            'servicesAvailability' => $this->servicesAvailabilityMap([]),
        ];
    }

    private function formatTimeForInput(?string $time): ?string
    {
        if ($time === null || $time === '') {
            return null;
        }

        return substr((string) $time, 0, 5);
    }

    /**
     * @param  array<int, string>|null  $keys
     * @return array<string, array<string, mixed>>
     */
    private function formatServices(?array $keys): array
    {
        $active = array_values(array_unique(array_filter($keys ?? [])));
        $result = [];

        foreach ($active as $key) {
            if (! isset(self::SERVICE_LABELS[$key])) {
                continue;
            }
            $meta = self::SERVICE_LABELS[$key];
            $result[$key] = [
                'key' => $key,
                'label' => $meta['label'],
                'shortLabel' => $meta['shortLabel'],
                'is_available' => true,
            ];
        }

        return $result;
    }

    /**
     * @param  array<int, string>|null  $keys
     */
    private function servicesAvailabilityMap(?array $keys): array
    {
        $map = array_fill_keys(array_keys(self::SERVICE_LABELS), false);
        foreach ($keys ?? [] as $key) {
            if (isset($map[$key])) {
                $map[$key] = true;
            }
        }

        return $map;
    }

    private function displayHallName(Station $station): string
    {
        if ($this->isBlankProfile($station)) {
            return '';
        }

        return $station->name ?? '';
    }
}

