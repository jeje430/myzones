<?php

namespace App\Http\Controllers;

use App\Services\PlutuLocalBankPaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PlutuPaymentCallbackController extends Controller
{
    public function __construct(
        private readonly PlutuLocalBankPaymentService $plutu,
    ) {}

    /**
     * Plutu redirects here after payment (success / cancel).
     */
    public function handle(Request $request): JsonResponse|RedirectResponse
    {
        Log::info('[Plutu] callback received', $request->all());

        try {
            $transaction = $this->plutu->handleCallback($request->all());
        } catch (\Throwable $e) {
            Log::error('[Plutu] callback error', ['error' => $e->getMessage()]);

            if ($request->boolean('api') || $request->wantsJson()) {
                return response()->json([
                    'error' => true,
                    'message' => $e->getMessage(),
                ], 422);
            }

            return redirect($this->frontendResultUrl('error'));
        }

        if ($request->boolean('api') || $request->wantsJson()) {
            return response()->json([
                'invoice_no' => $transaction->invoice_no,
                'status' => $transaction->status,
                'booking_id' => $transaction->booking_id,
                'paid_at' => $transaction->paid_at,
            ]);
        }

        return redirect($this->frontendResultUrl(
            $transaction->status === 'paid' ? 'success' : ($transaction->status === 'canceled' ? 'canceled' : 'failed'),
            $transaction->invoice_no,
        ));
    }

    /**
     * Sandbox quick test — only in debug mode.
     */
    public function sandboxTest(): JsonResponse|RedirectResponse
    {
        abort_unless(config('app.debug'), 404);

        try {
            $result = $this->plutu->createPayment(5.00);
        } catch (\Throwable $e) {
            return response()->json(['error' => true, 'message' => $e->getMessage()], 500);
        }

        if (! ($result['ok'] ?? false)) {
            return response()->json($result, 400);
        }

        return redirect()->away($result['payment_url']);
    }

    private function frontendResultUrl(string $status, ?string $invoiceNo = null): string
    {
        $base = rtrim(config('app.frontend_url', config('app.url')), '/');
        $query = http_build_query(array_filter([
            'status' => $status,
            'invoice_no' => $invoiceNo,
        ]));

        return $base.'/payment/result?'.$query;
    }
}
