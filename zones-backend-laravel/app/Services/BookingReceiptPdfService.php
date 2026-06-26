<?php

namespace App\Services;

use App\Models\Booking;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class BookingReceiptPdfService
{
    public function normalizePayload(array $data): array
    {
        $bookingType = $data['booking_type'] ?? 'regular';

        $paymentMethod = $this->normalizePaymentMethod($data['payment_method'] ?? null, $bookingType);

        $base = [
            'station_name' => trim((string) ($data['station_name'] ?? '')),
            'booking_number' => trim((string) ($data['booking_number'] ?? '')),
            'customer_name' => trim((string) ($data['customer_name'] ?? '')),
            'booking_date' => $this->formatDate($data['booking_date'] ?? null),
            'start_time' => $this->formatTime($data['start_time'] ?? null),
            'end_time' => $this->formatTime($data['end_time'] ?? null),
            'package_name' => trim((string) ($data['package_name'] ?? '')),
            'device_code' => trim((string) ($data['device_code'] ?? '')),
            'booking_type' => $bookingType,
            'booking_type_label' => $this->bookingTypeLabel($bookingType),
            'payment_method' => $paymentMethod,
            'payment_method_label' => $this->paymentMethodLabel($paymentMethod),
            'generated_at' => now()->format('Y-m-d H:i'),
        ];

        if ($bookingType === 'offer') {
            $before = (float) ($data['amount_before_discount'] ?? 0);
            $percent = (float) ($data['discount_percent'] ?? 0);
            $after = (float) ($data['amount_after_discount'] ?? max(0, $before - ($before * $percent / 100)));

            return array_merge($base, [
                'show_discount_section' => true,
                'show_loyalty_section' => false,
                'show_single_amount' => false,
                'amount_before_discount' => $this->formatMoney($before),
                'discount_percent' => rtrim(rtrim(number_format($percent, 2, '.', ''), '0'), '.'),
                'amount_after_discount' => $this->formatMoney($after),
            ]);
        }

        if ($bookingType === 'loyalty') {
            return array_merge($base, [
                'show_discount_section' => false,
                'show_loyalty_section' => true,
                'show_single_amount' => false,
                'amount_label' => 'Free',
                'loyalty_redemption_note' => trim((string) ($data['loyalty_redemption_note'] ?? 'Customer redeemed loyalty reward booking.')),
                'loyalty_coupon_label' => trim((string) ($data['loyalty_coupon_label'] ?? 'Loyalty Reward')),
                'loyalty_coupon_code' => trim((string) ($data['loyalty_coupon_code'] ?? '')),
                'loyalty_points_per_session' => (int) ($data['loyalty_points_per_session'] ?? 0),
                'loyalty_points_total' => (int) ($data['loyalty_points_total'] ?? 0),
                'estimated_sessions_required' => (int) ($data['estimated_sessions_required'] ?? 0),
            ]);
        }

        return array_merge($base, [
            'show_discount_section' => false,
            'show_loyalty_section' => false,
            'show_single_amount' => true,
            'amount' => $this->formatMoney((float) ($data['amount'] ?? 0)),
        ]);
    }

    public function fromBooking(Booking $booking): array
    {
        $booking->loadMissing(['station', 'device', 'package', 'user']);

        $bookingType = $booking->booking_type ?: ($booking->offer_id ? 'offer' : ($booking->total_price == 0 ? 'loyalty' : 'regular'));

        $payload = [
            'booking_type' => $bookingType,
            'station_name' => $booking->station?->name ?? '',
            'booking_number' => $booking->booking_number,
            'customer_name' => $booking->visitor_name ?: ($booking->user?->full_name ?? ''),
            'booking_date' => $booking->start_date?->format('Y-m-d'),
            'start_time' => $booking->start_time,
            'end_time' => $booking->end_time,
            'package_name' => $booking->package?->name ?? '',
            'device_code' => $booking->device?->device_code ?? '',
            'payment_method' => $booking->payment_method === 'online'
                ? 'online'
                : ($booking->payment_method === 'loyalty_reward' ? 'loyalty_reward' : 'on_arrival'),
        ];

        if ($bookingType === 'offer') {
            $before = (float) $booking->subtotal_price;
            $after = (float) $booking->total_price;
            $percent = (float) ($booking->discount_percent ?? ($before > 0 ? round((($before - $after) / $before) * 100, 2) : 0));

            $payload['amount_before_discount'] = $before;
            $payload['discount_percent'] = $percent;
            $payload['amount_after_discount'] = $after;
        } elseif ($bookingType === 'loyalty') {
            $settings = \App\Models\PlatformSetting::current();
            $payload['loyalty_coupon_label'] = $booking->loyalty_coupon_label ?: 'Loyalty Reward';
            $payload['loyalty_coupon_code'] = $booking->loyalty_coupon_code ?: 'LOYALTY-REWARD';
            $payload['loyalty_points_per_session'] = $booking->loyalty_points_per_session
                ?: $settings->loyalty_points_per_session;
            $payload['loyalty_points_total'] = $booking->loyalty_points_total
                ?: $booking->loyalty_points_redeemed
                ?: $settings->loyalty_minimum_points_required;
            $payload['estimated_sessions_required'] = $settings->estimatedSessionsRequired();
            $payload['loyalty_redemption_note'] = 'Customer redeemed loyalty reward booking.';
            $payload['payment_method'] = 'loyalty_reward';
        } else {
            $payload['amount'] = (float) $booking->total_price;
        }

        return $this->normalizePayload($payload);
    }

    public function generate(array $payload)
    {
        $viewData = $this->normalizePayload($payload);

        return Pdf::loadView('pdf.booking-receipt', $viewData)
            ->setPaper('a4', 'portrait')
            ->setOptions([
                'defaultFont' => 'dejavu sans',
                'isHtml5ParserEnabled' => true,
                'isRemoteEnabled' => false,
            ]);
    }

    public function generateFromBooking(Booking $booking)
    {
        return Pdf::loadView('pdf.booking-receipt', $this->fromBooking($booking))
            ->setPaper('a4', 'portrait')
            ->setOptions([
                'defaultFont' => 'dejavu sans',
                'isHtml5ParserEnabled' => true,
                'isRemoteEnabled' => false,
            ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function pdfOptions(): array
    {
        return [
            'defaultFont' => 'dejavu sans',
            'isHtml5ParserEnabled' => true,
            'isRemoteEnabled' => false,
        ];
    }

    public function saveForBooking(Booking $booking, ?array $payload = null): string
    {
        $pdf = $payload
            ? $this->generate($payload)
            : $this->generateFromBooking($booking);

        $filename = 'receipts/'.Str::slug($booking->booking_number).'-'.now()->format('YmdHis').'.pdf';

        Storage::disk('public')->put($filename, $pdf->output());

        $booking->update(['receipt_pdf_path' => $filename]);

        return $filename;
    }

    private function normalizePaymentMethod(?string $method, string $bookingType): string
    {
        if ($bookingType === 'loyalty' || $method === 'loyalty_reward') {
            return 'loyalty_reward';
        }

        $method = Str::lower(trim((string) $method));

        return in_array($method, ['online', 'electronic', 'paid'], true) ? 'online' : 'on_arrival';
    }

    private function bookingTypeLabel(string $type): string
    {
        return match ($type) {
            'offer' => 'Offer Booking',
            'loyalty' => 'Loyalty Reward Booking',
            default => 'Regular Booking',
        };
    }

    private function paymentMethodLabel(string $method): string
    {
        return match ($method) {
            'online' => 'Electronic Payment',
            'loyalty_reward' => 'Loyalty Reward',
            default => 'Cash on Arrival',
        };
    }

    private function formatDate(?string $value): string
    {
        if (! $value) {
            return '';
        }

        try {
            return Carbon::parse($value)->format('Y-m-d');
        } catch (\Throwable) {
            return (string) $value;
        }
    }

    private function formatTime(?string $value): string
    {
        if (! $value) {
            return '';
        }

        try {
            return Carbon::parse($value)->format('H:i');
        } catch (\Throwable) {
            return substr((string) $value, 0, 5);
        }
    }

    private function formatMoney(float $amount): string
    {
        return number_format($amount, 2, '.', '').' LYD';
    }
}
