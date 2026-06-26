<?php

namespace App\Http\Resources;

use App\Support\MediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $station = $this->resolvedStation();
        $stationId = $this->resolvedStationId();
        $roles = $this->relationLoaded('roles')
            ? $this->roles->pluck('name')->values()->all()
            : [];

        return [
            'id' => $this->id,
            'name' => $this->full_name,
            'full_name' => $this->full_name,
            'phone' => $this->phone,
            'email' => $this->email,
            'profile_image' => MediaUrl::resolve($this->profile_image),
            'account_status' => $this->account_status,
            'station_id' => $stationId,
            'hall_id' => $stationId,
            'station_name' => $station?->name,
            'hall_name' => $station?->name,
            'work_shift' => $this->work_shift,
            'email_verified_at' => $this->email_verified_at,
            'phone_verified_at' => $this->phone_verified_at,
            'last_login_at' => $this->last_login_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'roles' => $roles,
            'role' => $roles[0] ?? null,
        ];
    }
}
