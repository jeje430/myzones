<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\PaymentTransaction;
use App\Services\CustomerBookingService;
use App\Services\PaymentLogService;
use Illuminate\Support\Facades\Log;
use PlutuLaravel\Facades\PlutuLocalBankCards;

class PlutuLocalBankPaymentService
{
    public function createPayment(
        float $amount,
        ?int $userId = null,
        ?int $bookingId = null,
        ?string $returnUrl = null,
    ): array {
        $invoiceNo = $this->nextInvoiceNumber($bookingId);
        $returnUrl = $returnUrl ?: $this->defaultReturnUrl();

        $transaction = PaymentTransaction::create([
            'invoice_no' => $invoiceNo,
            'user_id' => $userId,
            'booking_id' => $bookingId,
            'amount' => $amount,
            'currency' => 'LYD',
            'gateway' => 'plutu_local_bank',
            'status' => 'pending',
        ]);

        Log::info('[Plutu] creating local bank payment', [
            'invoice_no' => $invoiceNo,
            'amount' => $amount,
            'return_url' => $returnUrl,
            'booking_id' => $bookingId,
        ]);

        $apiResponse = PlutuLocalBankCards::confirm($amount, $invoiceNo, $returnUrl);
        $original = $apiResponse->getOriginalResponse();

        if ($original->isSuccessful()) {
            $redirectUrl = $apiResponse->getRedirectUrl();

            if (empty($redirectUrl)) {
                $transaction->update(['status' => 'failed']);

                return [
                    'ok' => false,
                    'message' => 'Plutu returned empty redirect URL',
                    'response' => $original->getBody(),
                ];
            }

            $transaction->update(['redirect_url' => $redirectUrl]);

            return [
                'ok' => true,
                'payment_url' => $redirectUrl,
                'invoice_no' => $invoiceNo,
                'transaction_id' => $transaction->id,
            ];
        }

        if ($original->hasError()) {
            $transaction->update([
                'status' => 'failed',
                'callback_payload' => [
                    'error_code' => $original->getErrorCode(),
                    'error_message' => $original->getErrorMessage(),
                ],
            ]);

            return [
                'ok' => false,
                'code' => $original->getErrorCode(),
                'message' => $original->getErrorMessage(),
            ];
        }

        $transaction->update(['status' => 'failed']);

        return [
            'ok' => false,
            'message' => 'Unexpected Plutu response',
            'response' => $original->getBody(),
        ];
    }

    public function handleCallback(array $payload): PaymentTransaction
    {
        $invoiceNo = $payload['invoice_no'] ?? $payload['invoiceNo'] ?? null;

        if (! $invoiceNo) {
            throw new \InvalidArgumentException('Missing invoice number in callback');
        }

        $transaction = PaymentTransaction::where('invoice_no', $invoiceNo)->firstOrFail();

        $hashValid = $this->verifyCallbackHash($payload);

        if (! $hashValid) {
            Log::warning('[Plutu] callback hash mismatch', [
                'invoice_no' => $invoiceNo,
                'payload' => $payload,
            ]);
        }

        $approved = ($payload['approved'] ?? null) == 1;
        $canceled = ! empty($payload['canceled']);

        if ($approved) {
            $transaction->update([
                'status' => 'paid',
                'paid_at' => now(),
                'callback_payload' => $payload,
            ]);

            $this->markBookingPaid($transaction);
        } elseif ($canceled) {
            $transaction->update([
                'status' => 'canceled',
                'callback_payload' => $payload,
            ]);
        } else {
            $transaction->update([
                'status' => 'failed',
                'callback_payload' => $payload,
            ]);
        }

        Log::info('[Plutu] callback processed', [
            'invoice_no' => $invoiceNo,
            'status' => $transaction->status,
        ]);

        return $transaction->fresh();
    }

    public function verifyCallbackHash(array $payload): bool
    {
        $secretKey = config('plutu.secret_key');
        $receivedHash = $payload['hashed'] ?? null;

        if (empty($receivedHash) || empty($secretKey)) {
            return true;
        }

        $params = $payload;
        unset($params['hashed']);
        ksort($params);

        $dataString = '';
        foreach ($params as $key => $value) {
            if (is_array($value)) {
                continue;
            }
            $dataString .= $key.$value;
        }

        $computedHash = strtoupper(hash_hmac('sha256', $dataString, $secretKey));

        return hash_equals($computedHash, strtoupper((string) $receivedHash));
    }

    public function reconcileBookingPayment(Booking $booking): Booking
    {
        $paidTransaction = PaymentTransaction::query()
            ->where('booking_id', $booking->id)
            ->where('status', 'paid')
            ->latest('id')
            ->first();

        if ($paidTransaction && $booking->booking_status !== 'confirmed') {
            return app(CustomerBookingService::class)->finalizePaidOrConfirmed($booking);
        }

        return $booking;
    }

    /**
     * Apply Plutu callback payload for a booking owned by the customer.
     *
     * @param  array<string, mixed>  $payload
     */
    public function applyCallbackForBooking(Booking $booking, array $payload): PaymentTransaction
    {
        $invoiceNo = $payload['invoice_no'] ?? $payload['invoiceNo'] ?? null;
        if (! $invoiceNo) {
            throw new \InvalidArgumentException('Missing invoice number');
        }

        $transaction = PaymentTransaction::query()
            ->where('invoice_no', $invoiceNo)
            ->where('booking_id', $booking->id)
            ->firstOrFail();

        if ($transaction->status === 'paid') {
            $this->markBookingPaid($transaction);

            return $transaction->fresh();
        }

        $result = $this->handleCallback($payload);

        return $result;
    }

    private function markBookingPaid(PaymentTransaction $transaction): void
    {
        if (! $transaction->booking_id) {
            return;
        }

        $booking = Booking::query()->find($transaction->booking_id);
        if (! $booking) {
            return;
        }

        app(CustomerBookingService::class)->finalizePaidOrConfirmed($booking);

        app(PaymentLogService::class)->logElectronicPayment($transaction->fresh());
    }

    private function nextInvoiceNumber(?int $bookingId): string
    {
        $prefix = $bookingId ? 'BK-'.$bookingId : 'INV';

        return $prefix.'-'.now()->format('YmdHis').'-'.random_int(100, 999);
    }

    private function defaultReturnUrl(): string
    {
        return rtrim(config('services.plutu.return_url', config('app.url')), '/').'/payment/callback';
    }
}
