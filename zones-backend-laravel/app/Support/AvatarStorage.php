<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AvatarStorage
{
    private const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp'];

    public static function storeFromUpload(UploadedFile $file, ?string $oldPath = null): string
    {
        $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');
        if ($extension === 'jpeg') {
            $extension = 'jpg';
        }
        if (! in_array($extension, self::ALLOWED_EXTENSIONS, true)) {
            $extension = 'jpg';
        }

        $filename = Str::uuid().'.'.$extension;
        $path = 'avatars/'.$filename;

        Storage::disk('public')->putFileAs('avatars', $file, $filename);

        self::deleteStoredFile($oldPath);

        return $path;
    }

    public static function deleteAvatar(?string $path): void
    {
        self::deleteStoredFile($path);
    }

    public static function deleteStoredFile(?string $path): void
    {
        if ($path === null || $path === '') {
            return;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return;
        }

        if (str_starts_with($path, 'data:image')) {
            return;
        }

        Storage::disk('public')->delete($path);
    }
}
