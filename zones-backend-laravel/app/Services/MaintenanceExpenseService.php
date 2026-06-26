<?php

namespace App\Services;

use App\Models\DeviceFault;
use App\Models\HallExpense;
use App\Models\User;

class MaintenanceExpenseService
{
    public function createFromResolvedFault(DeviceFault $fault, User $actor): ?HallExpense
    {
        if (HallExpense::query()->where('device_fault_id', $fault->id)->exists()) {
            return HallExpense::query()->where('device_fault_id', $fault->id)->first();
        }

        $cost = (float) $fault->maintenance_cost;
        if ($cost <= 0) {
            return null;
        }

        $fault->loadMissing(['device', 'station']);
        $device = $fault->device;
        $station = $fault->station;

        if (! $device || ! $station) {
            return null;
        }

        $faultTypeLabel = $this->faultTypeLabel($fault);
        $deviceName = $device->display_name ?: ('جهاز #'.$device->id);
        $hallName = $station->name ?: 'الصالة';
        $createdBy = $fault->maintenance_employee_name ?: $actor->name;

        $name = sprintf('صيانة — %s — %s', $deviceName, $faultTypeLabel);
        $notes = sprintf(
            'جهاز: %s | نوع الصيانة: %s | الصالة: %s | بواسطة: %s',
            $deviceName,
            $faultTypeLabel,
            $hallName,
            $createdBy,
        );

        if ($fault->details) {
            $notes .= ' | تفاصيل: '.$fault->details;
        }

        $resolvedDate = $fault->resolved_at?->toDateString() ?? now()->toDateString();

        return HallExpense::create([
            'station_id' => $station->id,
            'name' => $name,
            'amount' => $cost,
            'is_paid' => false,
            'added_at' => $resolvedDate,
            'paid_at' => null,
            'notes' => $notes,
            'category' => 'maintenance',
            'device_fault_id' => $fault->id,
            'created_by' => $actor->id,
        ]);
    }

    private function faultTypeLabel(DeviceFault $fault): string
    {
        if ($fault->fault_type === 'other' && $fault->fault_type_custom) {
            return trim($fault->fault_type_custom);
        }

        return match ($fault->fault_type) {
            'screen' => 'عطل شاشة',
            'controller' => 'عطل تحكم',
            'network' => 'عطل شبكة',
            'audio' => 'عطل صوت',
            'power' => 'عطل تشغيل',
            default => $fault->fault_type_custom ?: 'صيانة',
        };
    }
}
