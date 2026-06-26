<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\PackageResource;
use App\Models\Package;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ManagerPackageController extends Controller
{
    use ResolvesManagerStation;

    public function index(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $packages = Package::query()
            ->where('station_id', $station->id)
            ->when($request->boolean('active_only'), fn ($q) => $q->where('is_active', true))
            ->when($request->filled('q'), function ($q) use ($request) {
                $term = '%'.trim($request->string('q')).'%';
                $q->where('name', 'like', $term);
            })
            ->orderBy('name')
            ->get();

        return response()->json([
            'packages' => PackageResource::collection($packages)->resolve(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $this->validatePackage($request);

        $slug = $validated['slug'] ?? Str::slug($validated['name']).'-'.$station->id;

        $package = Package::create([
            'station_id' => $station->id,
            'slug' => $slug,
            ...$validated,
        ]);

        return response()->json([
            'message' => 'تم إضافة الباقة',
            'package' => (new PackageResource($package))->resolve(),
        ], 201);
    }

    public function update(Request $request, Package $package): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station || (int) $package->station_id !== (int) $station->id) {
            return response()->json(['message' => 'الباقة غير موجودة'], 404);
        }

        $validated = $this->validatePackage($request, $package);

        $package->update($validated);

        return response()->json([
            'message' => 'تم تحديث الباقة',
            'package' => (new PackageResource($package->fresh()))->resolve(),
        ]);
    }

    public function destroy(Request $request, Package $package): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station || (int) $package->station_id !== (int) $station->id) {
            return response()->json(['message' => 'الباقة غير موجودة'], 404);
        }

        $package->delete();

        return response()->json([
            'message' => 'تم حذف الباقة',
        ]);
    }

    private function validatePackage(Request $request, ?Package $package = null): array
    {
        $station = $this->resolveManagerStation($request->user());

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:120',
            'slug' => [
                'nullable',
                'string',
                'max:120',
                Rule::unique('packages', 'slug')->ignore($package?->id),
            ],
            'package_type' => 'sometimes|required|in:ps5,pc,vr,xbox,simulator,vip',
            'type' => 'sometimes|required|in:ps5,pc,vr,xbox,simulator,vip',
            'hourly_price' => 'sometimes|numeric|min:0',
            'price' => 'sometimes|numeric|min:0',
            'description' => 'nullable|string|max:2000',
            'is_active' => 'sometimes|boolean',
        ]);

        $hourlyPrice = $validated['hourly_price'] ?? $validated['price'] ?? $package?->hourly_price;

        return array_filter([
            'name' => $validated['name'] ?? $package?->name,
            'package_type' => $validated['package_type'] ?? $validated['type'] ?? $package?->package_type,
            'hourly_price' => $hourlyPrice,
            'description' => $validated['description'] ?? $package?->description,
            'is_active' => array_key_exists('is_active', $validated)
                ? (bool) $validated['is_active']
                : $package?->is_active,
        ], fn ($v) => $v !== null);
    }
}
