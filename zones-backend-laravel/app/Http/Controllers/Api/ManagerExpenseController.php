<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\HallExpenseResource;
use App\Models\HallExpense;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ManagerExpenseController extends Controller
{
    use ResolvesManagerStation;

    public function index(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $expenses = HallExpense::query()
            ->where('station_id', $station->id)
            ->orderByDesc('added_at')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'expenses' => HallExpenseResource::collection($expenses)->resolve(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $this->validatedExpensePayload($request);

        $expense = HallExpense::create([
            'station_id' => $station->id,
            ...$validated,
        ]);

        return response()->json([
            'message' => 'تمت إضافة المصروف',
            'expense' => (new HallExpenseResource($expense))->resolve(),
        ], 201);
    }

    public function update(Request $request, HallExpense $expense): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        abort_unless((int) $expense->station_id === (int) $station->id, 404);

        $validated = $this->validatedExpensePayload($request, partial: true);
        $expense->update($validated);

        return response()->json([
            'message' => 'تم تحديث المصروف',
            'expense' => (new HallExpenseResource($expense->fresh()))->resolve(),
        ]);
    }

    public function destroy(Request $request, HallExpense $expense): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        abort_unless((int) $expense->station_id === (int) $station->id, 404);

        $expense->delete();

        return response()->json(['message' => 'تم حذف المصروف']);
    }

    public function destroyBulk(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $request->validate([
            'ids' => 'required|array|min:1',
            'ids.*' => 'integer|exists:hall_expenses,id',
        ]);

        $deleted = HallExpense::query()
            ->where('station_id', $station->id)
            ->whereIn('id', $validated['ids'])
            ->delete();

        return response()->json([
            'message' => 'تم حذف المصروفات المحددة',
            'deleted_count' => $deleted,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validatedExpensePayload(Request $request, bool $partial = false): array
    {
        $rules = [
            'name' => ($partial ? 'sometimes|' : '').'required|string|max:120',
            'amount' => ($partial ? 'sometimes|' : '').'required|numeric|min:0',
            'is_paid' => 'sometimes|boolean',
            'added_at' => ($partial ? 'sometimes|' : '').'required|date',
            'paid_at' => 'nullable|date',
            'notes' => 'nullable|string|max:1000',
        ];

        $validated = $request->validate($rules);

        if (array_key_exists('is_paid', $validated)) {
            $validated['is_paid'] = (bool) $validated['is_paid'];
        } else {
            $validated['is_paid'] = true;
        }

        if (! ($validated['is_paid'] ?? true)) {
            $validated['paid_at'] = null;
        } elseif (! array_key_exists('paid_at', $validated) || $validated['paid_at'] === null) {
            $validated['paid_at'] = $validated['added_at'] ?? now()->toDateString();
        }

        return $validated;
    }
}
