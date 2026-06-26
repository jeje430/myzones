<?php



namespace App\Http\Controllers\Api;



use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;

use App\Http\Controllers\Controller;

use App\Http\Resources\ManagerStationResource;

use App\Models\Station;

use App\Support\StationImageStorage;

use Illuminate\Http\JsonResponse;

use Illuminate\Http\Request;



class ManagerStationController extends Controller

{

    use ResolvesManagerStation;



    private const ALLOWED_SERVICE_KEYS = [

        'ps5', 'xbox', 'vr', 'vip', 'simulator', 'racing', 'pc', 'free_wifi', 'snacks', 'cafeteria',

    ];



    public function show(Request $request): JsonResponse

    {

        $station = $this->resolveManagerStation($request->user());



        if (! $station) {

            return $this->managerStationMissingResponse();

        }



        return response()->json([

            'station' => (new ManagerStationResource($station))->resolve(),

        ]);

    }



    public function update(Request $request): JsonResponse

    {

        $station = $this->resolveManagerStation($request->user());



        if (! $station) {

            return $this->managerStationMissingResponse();

        }



        if ($this->wantsStationReset($request)) {

            return $this->resetStation($station, $request);

        }



        $validated = $request->validate([

            'hallName' => 'nullable|string|max:255',

            'name' => 'nullable|string|max:255',

            'description' => 'nullable|string|max:5000',

            'city' => 'nullable|string|max:120',

            'address' => 'nullable|string|max:1000',

            'mapLink' => 'nullable|string|max:500',

            'map_link' => 'nullable|string|max:500',

            'latitude' => 'nullable|numeric|between:-90,90',

            'longitude' => 'nullable|numeric|between:-180,180',

            'phone' => 'nullable|string|max:30',

            'workHoursFrom' => 'nullable|date_format:H:i',

            'workHoursTo' => 'nullable|date_format:H:i',

            'opens_at' => 'nullable|date_format:H:i',

            'closes_at' => 'nullable|date_format:H:i',

            'image' => 'nullable|string',
            'cover_image' => 'nullable|file|image|mimes:jpeg,jpg,png,webp,gif|max:5120',

            'remove_cover_image' => 'nullable|boolean',

            'available_services' => 'nullable|array',

            'available_services.*' => 'string|max:40',

            'servicesAvailability' => 'nullable|array',
            'complete_setup' => 'nullable|boolean',
            'publish_to_app' => 'nullable|boolean',
        ]);



        $nameInput = $this->inputString($request, $validated, 'hallName', 'name');

        $name = $nameInput !== null ? trim($nameInput) : trim($station->name);



        $mapLink = $this->inputString($request, $validated, 'mapLink', 'map_link');

        if ($mapLink !== null) {

            $mapLink = trim($mapLink) !== '' ? trim($mapLink) : null;

        } else {

            $mapLink = $station->map_link;

        }



        $opensAt = $validated['workHoursFrom'] ?? $validated['opens_at'] ?? null;

        $closesAt = $validated['workHoursTo'] ?? $validated['closes_at'] ?? null;

        $imageInput = $validated['image'] ?? null;

        if ($request->hasFile('cover_image')) {
            $coverPath = StationImageStorage::storeCoverFromUpload(
                $request->file('cover_image'),
                $station->cover_image,
            );
        } elseif ($request->boolean('remove_cover_image')) {

            StationImageStorage::deleteCover($station->cover_image);

            $coverPath = null;

        } else {

            $coverPath = StationImageStorage::storeCoverImage($imageInput, $station->cover_image);

        }



        $serviceKeys = $this->normalizeServiceKeys(

            $validated['available_services'] ?? null,

            $validated['servicesAvailability'] ?? null,

            $request->has('servicesAvailability') || $request->has('available_services')

                ? []

                : $station->available_services,

        );



        $city = $this->nullableTrimmed($request, $validated, 'city', $station->city);

        $address = $this->nullableTrimmed($request, $validated, 'address', $station->address);

        $phone = $this->nullableTrimmed($request, $validated, 'phone', $station->phone);

        $description = $request->has('description')

            ? ($validated['description'] ?? null)

            : $station->description;



        $latitude = $request->has('latitude')

            ? ($validated['latitude'] ?? null)

            : $station->latitude;

        $longitude = $request->has('longitude')

            ? ($validated['longitude'] ?? null)

            : $station->longitude;



        $dbName = $name !== '' ? $name : $this->placeholderName($station);



        $publish = $this->resolvePublishState(
            $request,
            $name,
            $address,
            $serviceKeys,
            $opensAt,
            $closesAt,
            $station,
        );

        if (
            ($request->boolean('complete_setup') || $request->boolean('publish_to_app'))
            && empty($publish['is_published'])
            && ! ($station->is_published && $this->isSetupComplete(
                $name,
                $address,
                $serviceKeys,
                $opensAt,
                $closesAt,
                $station,
            ))
        ) {
            return response()->json([
                'message' => 'أكمل بيانات الصالة قبل النشر: الاسم، العنوان، ساعات العمل، وخدمة واحدة على الأقل.',
            ], 422);
        }

        $station->update(array_merge([

            'name' => $dbName,

            'description' => $description !== '' ? $description : null,

            'city' => $city !== '' ? $city : null,

            'address' => $address !== '' ? $address : null,

            'map_link' => $mapLink,

            'latitude' => $latitude,

            'longitude' => $longitude,

            'phone' => $phone !== '' ? $phone : null,

            'opens_at' => $opensAt ? $opensAt.':00' : $station->opens_at,

            'closes_at' => $closesAt ? $closesAt.':00' : $station->closes_at,

            'cover_image' => $coverPath,

            'available_services' => $serviceKeys,

            'manager_id' => $station->manager_id ?? $request->user()->id,

        ], $publish));



        $station->refresh();



        return response()->json([

            'message' => ($publish['is_published'] ?? $station->is_published)

                ? 'تم حفظ البيانات — الصالة ظاهرة للزبائن في التطبيق'

                : 'تم حفظ البيانات — أكمل الإعداد واضغط «حفظ التغييرات» لتظهر في التطبيق',

            'station' => (new ManagerStationResource($station))->resolve(),

            'published' => (bool) $station->is_published,

            'setup_completed' => (bool) $station->is_published,

        ]);

    }



    public function reset(Request $request): JsonResponse

    {

        $station = $this->resolveManagerStation($request->user());



        if (! $station) {

            return $this->managerStationMissingResponse();

        }



        return $this->resetStation($station, $request);

    }



    private function wantsStationReset(Request $request): bool

    {

        foreach (['reset_station', 'resetStation'] as $key) {

            if ($request->has($key) && filter_var($request->input($key), FILTER_VALIDATE_BOOLEAN)) {

                return true;

            }

        }



        return false;

    }



    private function resetStation(Station $station, Request $request): JsonResponse

    {

        StationImageStorage::deleteCover($station->cover_image);



        $station->update([
            'name' => $this->placeholderName($station),
            'description' => null,
            'city' => null,
            'address' => null,
            'map_link' => null,
            'latitude' => null,
            'longitude' => null,
            'phone' => null,
            'cover_image' => null,
            'available_services' => [],
            'opens_at' => null,
            'closes_at' => null,
            'is_active' => false,
            'bookings_enabled' => false,
            'is_published' => false,
            'published_at' => null,
            'setup_completed_at' => null,
            'manager_id' => $station->manager_id ?? $request->user()->id,
        ]);



        $station->refresh();



        return response()->json([

            'message' => 'تم مسح بيانات الصالة — يمكنك الإضافة من جديد',

            'station' => (new ManagerStationResource($station))->resolve(),

            'published' => false,

        ]);

    }



    private function placeholderName(Station $station): string

    {

        return 'صالة #'.$station->id;

    }



    private function inputString(Request $request, array $validated, string $camel, string $snake): ?string

    {

        if ($request->has($camel)) {

            return $validated[$camel] ?? '';

        }

        if ($request->has($snake)) {

            return $validated[$snake] ?? '';

        }



        return null;

    }



    private function nullableTrimmed(Request $request, array $validated, string $key, ?string $fallback): ?string

    {

        if (! $request->has($key)) {

            return $fallback;

        }



        return trim((string) ($validated[$key] ?? ''));

    }



    /**

     * @param  array<int, string>|null  $list

     * @param  array<string, bool>|null  $map

     * @param  array<int, string>|null  $fallback

     * @return array<int, string>

     */

    private function normalizeServiceKeys(?array $list, ?array $map, ?array $fallback): array

    {

        if (is_array($map)) {

            $list = array_keys(array_filter($map, fn ($v) => (bool) $v));

        }



        if (! is_array($list)) {

            $list = $fallback ?? [];

        }



        return array_values(array_unique(array_filter($list, fn ($key) => in_array($key, self::ALLOWED_SERVICE_KEYS, true))));

    }



    /**
     * @return array<string, mixed>
     */
    private function resolvePublishState(
        Request $request,
        string $name,
        ?string $address,
        array $serviceKeys,
        ?string $opensAt,
        ?string $closesAt,
        Station $station,
    ): array {
        $wantsPublish = $request->boolean('complete_setup') || $request->boolean('publish_to_app');
        $ready = $this->isSetupComplete($name, $address, $serviceKeys, $opensAt, $closesAt, $station);

        if ($wantsPublish && $ready) {
            return [
                'is_published' => true,
                'is_active' => true,
                'bookings_enabled' => true,
                'published_at' => $station->published_at ?? now(),
                'setup_completed_at' => now(),
            ];
        }

        if ($wantsPublish && ! $ready) {
            return [
                'is_published' => false,
                'is_active' => false,
                'bookings_enabled' => false,
                'published_at' => null,
                'setup_completed_at' => null,
            ];
        }

        if ($station->is_published && ! $ready) {
            return [
                'is_published' => false,
                'is_active' => false,
                'bookings_enabled' => false,
                'published_at' => null,
                'setup_completed_at' => null,
            ];
        }

        return [];
    }

    private function isSetupComplete(
        string $name,
        ?string $address,
        array $serviceKeys,
        ?string $opensAt,
        ?string $closesAt,
        Station $station,
    ): bool {
        if (trim($name) === '' || $this->isPlaceholderName($name, $station)) {
            return false;
        }

        if (trim((string) $address) === '') {
            return false;
        }

        if ($opensAt === null || $closesAt === null) {
            $opensAt = $station->opens_at
                ? substr((string) $station->opens_at, 0, 5)
                : null;
            $closesAt = $station->closes_at
                ? substr((string) $station->closes_at, 0, 5)
                : null;
        }

        if ($opensAt === null || $closesAt === null) {
            return false;
        }

        return count($serviceKeys) > 0;
    }

    private function isPlaceholderName(string $name, Station $station): bool
    {
        return trim($name) === $this->placeholderName($station);
    }

    /**
     * @deprecated Use resolvePublishState()
     *
     * @return array<string, bool>
     */
    private function publishFlags(string $name, ?string $address): array
    {
        return [];
    }
}


