<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentTransaction;
use App\Services\PlutuLocalBankPaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlutuPaymentController extends Controller
{
    public function __construct(
        private readonly PlutuLocalBankPaymentService $plutu,
    ) {}

    /**
     * Create Plutu Local Bank Cards payment session.
     * Flutter/React send amount (+ optional booking_id) and receive payment_url.
     */
    public function createLocalBankPayment(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:0.01|max:50000',
            'booking_id' => 'nullable|integer|exists:bookings,id',
            'return_url' => 'nullable|url|max:500',
        ]);

        $userId = $request->user()?->id;

        try {
            $result = $this->plutu->createPayment(
                amount: (float) $validated['amount'],
                userId: $userId,
                bookingId: $validated['booking_id'] ?? null,
                returnUrl: $validated['return_url'] ?? null,
            );
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'error' => true,
                'message' => $e->getMessage(),
            ], 500);
        }

        if (! ($result['ok'] ?? false)) {
            return response()->json([
                'error' => true,
                'code' => $result['code'] ?? null,
                'message' => $result['message'] ?? 'Payment creation failed',
                'response' => $result['response'] ?? null,
            ], 400);
        }

        return response()->json([
            'payment_url' => $result['payment_url'],
            'invoice_no' => $result['invoice_no'],
            'transaction_id' => $result['transaction_id'],
        ]);
    }

    /**
     * Check payment transaction status (for Flutter polling after return).
     */
    public function show(string $invoiceNo): JsonResponse
    {
        $transaction = PaymentTransaction::where('invoice_no', $invoiceNo)->firstOrFail();

        return response()->json([
            'invoice_no' => $transaction->invoice_no,
            'amount' => $transaction->amount,
            'status' => $transaction->status,
            'booking_id' => $transaction->booking_id,
            'paid_at' => $transaction->paid_at,
        ]);
    }
}
