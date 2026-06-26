<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ManagerOfferResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $package = $this->whenLoaded('package');
        $station = $this->whenLoaded('station');

        return [
            'id' => (int) $this->id,
            'station_id' => $this->station_id ? (int) $this->station_id : null,
            'package_id' => $this->package_id ? (int) $this->package_id : null,
            'title' => $this->title,
            'description' => $this->description,
            'valid_from' => $this->valid_from?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'original_price' => (float) $this->original_price,
            'discounted_price' => (float) $this->discounted_price,
            'discount_percent' => (int) ($this->discount_percent ?? 0),
            'is_active' => (bool) $this->is_active,
            'package_name' => $package?->name,
            'station_name' => $station?->name,
            'usage_count' => (int) ($this->bookings_count ?? 0),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
