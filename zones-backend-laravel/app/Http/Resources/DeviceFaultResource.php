<?php

namespace App\Http\Resources;

use App\Models\DeviceFault;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceFaultResource extends JsonResource
{
    /** @var DeviceFault */
    public $resource;

    public function toArray(Request $request): array
    {
        $fault = $this->resource;
        $device = $fault->relationLoaded('device') ? $fault->device : null;

        $tz = config('app.timezone', 'Africa/Tripoli');
        $isScheduled = $fault->reported_at
            && $fault->reported_at->greaterThan(Carbon::now($tz)->startOfDay());

        return [
            'id' => $fault->id,
            'deviceId' => $fault->device_id,
            'device_id' => $fault->device_id,
            'deviceName' => $device?->display_name ?? '',
            'device_name' => $device?->display_name ?? '',
            'deviceType' => $device?->device_type ?? '',
            'device_type' => $device?->device_type ?? '',
            'deviceTypeLabel' => $device ? $this->typeLabel($device->device_type) : '—',
            'faultType' => $fault->fault_type,
            'fault_type' => $fault->fault_type,
            'faultTypeCustom' => $fault->fault_type_custom,
            'fault_type_custom' => $fault->fault_type_custom,
            'status' => $fault->status,
            'faultDate' => $fault->reported_at?->format('Y-m-d'),
            'fault_date' => $fault->reported_at?->format('Y-m-d'),
            'applyMaintenanceNow' => ! $isScheduled,
            'apply_maintenance_now' => ! $isScheduled,
            'isScheduled' => $isScheduled,
            'createdAt' => $fault->reported_at?->toIso8601String(),
            'created_at' => $fault->reported_at?->toIso8601String(),
            'resolvedAt' => $fault->resolved_at?->toIso8601String(),
            'resolved_at' => $fault->resolved_at?->toIso8601String(),
            'maintenanceCost' => (float) $fault->maintenance_cost,
            'maintenance_cost' => (float) $fault->maintenance_cost,
            'maintenanceEmployeeName' => $fault->maintenance_employee_name,
            'maintenance_employee_name' => $fault->maintenance_employee_name,
            'details' => $fault->details ?? '',
            'archived' => (bool) $fault->archived,
        ];
    }

    private function typeLabel(string $type): string
    {
        return match ($type) {
            'ps5' => 'PlayStation',
            'pc' => 'PC Gaming',
            'vr' => 'VR',
            'xbox' => 'Xbox',
            'simulator' => 'Simulator',
            'vip' => 'VIP',
            default => strtoupper($type),
        };
    }
}
