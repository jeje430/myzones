<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReviewResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'category' => $this->category,
            'stars' => (int) $this->stars,
            'submitted_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
