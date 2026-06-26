<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class StationImageStorage
{
    public static function storeCoverFromUpload(UploadedFile $file, ?string $oldPath = null): string
    {
        $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');
        if ($extension === 'jpeg') {
            $extension = 'jpg';
        }
        if (! in_array($extension, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
            $extension = 'jpg';
        }

        $path = 'stations/covers/'.Str::uuid().'.'.$extension;
        Storage::disk('public')->putFileAs(
            'stations/covers',
            $file,
            basename($path),
        );

        self::deleteStoredFile($oldPath);

        return $path;
    }

    public static function storeCoverImage(?string $input, ?string $oldPath = null): ?string
    {
        if ($input === null || $input === '') {
            return $oldPath;
        }

        if ($input === '__REMOVE__') {
            self::deleteStoredFile($oldPath);

            return null;
        }

        if (! str_starts_with($input, 'data:image')) {
            if (strlen($input) > 255) {
                return $oldPath;
            }

            return $input;
        }

        if (! preg_match('/^data:image\/(\w+);base64,/', $input, $matches)) {
            return $oldPath;
        }

        $extension = strtolower($matches[1] === 'jpeg' ? 'jpg' : $matches[1]);
        if (! in_array($extension, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
            $extension = 'jpg';
        }

        $data = substr($input, strpos($input, ',') + 1);
        $binary = base64_decode($data, true);

        if ($binary === false) {
            return $oldPath;
        }

        $path = 'stations/covers/'.Str::uuid().'.'.$extension;
        Storage::disk('public')->put($path, $binary);

        if ($oldPath && ! str_starts_with($oldPath, 'http')) {
            Storage::disk('public')->delete($oldPath);
        }

        return $path;
    }

    public static function deleteCover(?string $path): void
    {
        self::deleteStoredFile($path);
    }

    private static function deleteStoredFile(?string $path): void
    {
        if ($path === null || $path === '') {
            return;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return;
        }

        Storage::disk('public')->delete($path);
    }
}
