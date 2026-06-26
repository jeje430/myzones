<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Station;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

trait BuildsPublishedLoungeQuery
{
    /**
     * @return Builder<Station>
     */
    protected function publishedLoungesQuery(): Builder
    {
        return Station::query()
            ->customerVisible()
            ->with([
                'packages' => fn ($q) => $q->where('is_active', true),
                'devices',
                'reviews' => fn ($q) => $q->latest(),
            ]);
    }

    /**
     * @param  Builder<Station>  $query
     * @return Builder<Station>
     */
    protected function applyLoungeCatalogFilters(Builder $query, Request $request): Builder
    {
        if ($request->filled('q')) {
            $term = '%'.trim($request->string('q')).'%';
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', $term)
                    ->orWhere('city', 'like', $term)
                    ->orWhere('address', 'like', $term)
                    ->orWhere('description', 'like', $term);
            });
        }

        if ($request->filled('city')) {
            $query->where('city', 'like', '%'.trim($request->string('city')).'%');
        }

        if ($request->filled('service')) {
            $service = trim($request->string('service'));
            $query->whereJsonContains('available_services', $service);
        }

        return $query;
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Station>  $stations
     * @return \Illuminate\Support\Collection<int, Station>
     */
    protected function filterOpenNow($stations)
    {
        return $stations->filter(function (Station $station) {
            $resource = new \App\Http\Resources\LoungeCatalogResource($station);

            return (bool) $resource->toArray(request())['is_open'];
        })->values();
    }
}
