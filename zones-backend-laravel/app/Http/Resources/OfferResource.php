<?php

namespace App\Http\Resources;

use App\Support\MediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OfferResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $package = $this->relationLoaded('package') ? $this->package : null;
        $station = $this->relationLoaded('station') ? $this->station : null;

        return [
            'id' => (int) $this->id,
            'title' => $this->title,
            'offer_image' => MediaUrl::resolve($this->offer_image)
                ?? MediaUrl::resolve($package?->thumbnail)
                ?? '',
            'description' => $this->description,
            'valid_from' => $this->valid_from?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'original_price' => (float) $this->original_price,
            'discounted_price' => (float) $this->discounted_price,
            'discount_percent' => (int) ($this->discount_percent ?? 0),
            'station_id' => (int) ($this->station_id ?? 0),
            'package_id' => (int) ($this->package_id ?? 0),
            'station_name' => $station?->name ?? '',
            'package_name' => $package?->name ?? '',
            'terms' => $this->terms ?? [],
            'time_slots' => OfferTimeSlotResource::collection($this->whenLoaded('timeSlots'))->resolve(),
        ];
    }
}
