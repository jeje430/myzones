<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\PaymentTransaction;

class PaymentLogService
{
    /**
     * Log an electronic payment immediately after gateway verification.
     */
    public function logElectronicPayment(PaymentTransaction $transaction): ?Payment
    {
        if ($transaction->status !== 'paid' || ! $transaction->booking_id) {
            return null;
        }

        $booking = Booking::query()->find($transaction->booking_id);
        if (! $booking || in_array($booking->booking_type, ['loyalty'], true)) {
            return null;
        }

        if ($this->paymentExistsForBooking($booking->id)) {
            return Payment::query()->where('booking_id', $booking->id)->first();
        }

        return Payment::create([
            'booking_id' => $booking->id,
            'user_id' => $transaction->user_id ?? $booking->user_id,
            'amount' => $transaction->amount,
            'payment_method' => 'electronic',
            'transaction_ref' => $transaction->invoice_no,
            'status' => 'completed',
            'paid_at' => $transaction->paid_at ?? now(),
        ]);
    }

    /**
     * Log pay-on-arrival payment only when attendance is registered at check-in.
     */
    public function logPayOnArrivalPayment(Booking $booking): ?Payment
    {
        if ($booking->payment_method !== 'cash') {
            return null;
        }

        if ($booking->payment_status !== 'paid') {
            return null;
        }

        if (in_array($booking->booking_type, ['loyalty'], true)) {
            return null;
        }

        if (! $booking->is_checked_in || ! $booking->checked_in_at) {
            return null;
        }

        if ($this->paymentExistsForBooking($booking->id)) {
            return Payment::query()->where('booking_id', $booking->id)->first();
        }

        return Payment::create([
            'booking_id' => $booking->id,
            'user_id' => $booking->user_id,
            'amount' => $booking->total_price,
            'payment_method' => 'pay_on_arrival',
            'transaction_ref' => $booking->booking_number,
            'status' => 'completed',
            'paid_at' => $booking->checked_in_at,
        ]);
    }

    private function paymentExistsForBooking(int $bookingId): bool
    {
        return Payment::query()
            ->where('booking_id', $bookingId)
            ->where('status', 'completed')
            ->exists();
    }
}
