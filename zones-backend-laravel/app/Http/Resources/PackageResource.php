<?php

namespace App\Http\Resources;

use App\Models\Package;
use App\Support\MediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PackageResource extends JsonResource
{
    /** @var Package */
    public $resource;

    public function toArray(Request $request): array
    {
        $package = $this->resource;

        return [
            'id' => $package->id,
            'station_id' => $package->station_id,
            'name' => $package->name,
            'slug' => $package->slug,
            'package_type' => $package->package_type,
            'type' => $package->package_type,
            'hourly_price' => (float) $package->hourly_price,
            'price' => (string) $package->hourly_price,
            'minimum_hours' => (int) ($package->minimum_hours ?? 1),
            'maximum_hours' => $package->maximum_hours ? (int) $package->maximum_hours : null,
            'description' => $package->description,
            'thumbnail' => MediaUrl::resolve($package->thumbnail),
            'is_active' => (bool) $package->is_active,
            'is_archived' => ! $package->is_active,
            'average_rating' => (float) $package->average_rating,
            'created_at' => $package->created_at?->toIso8601String(),
            'updated_at' => $package->updated_at?->toIso8601String(),
        ];
    }
}
