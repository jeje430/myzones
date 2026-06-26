<?php

namespace App\Http\Resources;

use App\Models\HallExpense;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin HallExpense */
class HallExpenseResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'amount' => (float) $this->amount,
            'is_paid' => (bool) $this->is_paid,
            'added_at' => $this->added_at?->format('Y-m-d'),
            'paid_at' => $this->paid_at?->format('Y-m-d'),
            'notes' => $this->notes,
            'category' => $this->category,
            'device_fault_id' => $this->device_fault_id,
            'created_by' => $this->created_by,
        ];
    }
}
