<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OfferTimeSlotResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (int) $this->id,
            'time_range' => $this->time_range,
            'is_available' => (bool) $this->is_available,
        ];
    }
}
