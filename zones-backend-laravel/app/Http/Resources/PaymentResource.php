<?php

namespace App\Http\Resources;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Payment */
class PaymentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $booking = $this->relationLoaded('booking') ? $this->booking : null;
        $user = $this->relationLoaded('user') ? $this->user : null;

        $customerName = $user?->name
            ?? $booking?->visitor_name
            ?? '—';

        return [
            'id' => $this->id,
            'transaction_ref' => $this->transaction_ref,
            'customer_name' => $customerName,
            'booking_id' => $this->booking_id,
            'booking_number' => $booking?->booking_number,
            'booking_details' => $booking ? [
                'start_date' => $booking->start_date?->format('Y-m-d'),
                'start_time' => $booking->start_time,
                'end_time' => $booking->end_time,
                'hours_count' => $booking->hours_count,
            ] : null,
            'amount' => (float) $this->amount,
            'payment_method' => $this->payment_method,
            'status' => $this->status,
            'paid_at' => $this->paid_at?->toIso8601String(),
        ];
    }
}
