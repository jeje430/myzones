<?php



namespace App\Http\Controllers\Api;



use App\Http\Controllers\Controller;

use App\Http\Resources\UserResource;

use App\Support\AvatarStorage;

use App\Support\MediaUrl;

use Illuminate\Http\JsonResponse;

use Illuminate\Http\Request;



class ProfileAvatarController extends Controller

{

    public function store(Request $request): JsonResponse

    {

        return $this->upload($request);

    }



    public function update(Request $request): JsonResponse

    {

        return $this->upload($request);

    }



    public function destroy(Request $request): JsonResponse

    {

        $user = $request->user();



        AvatarStorage::deleteAvatar($user->profile_image);



        $user->update(['profile_image' => null]);

        $user->load('roles');



        return response()->json([

            'success' => true,

            'message' => 'Avatar deleted successfully',

            'avatar_url' => null,

            'user' => new UserResource($user),

        ]);

    }



    private function upload(Request $request): JsonResponse

    {

        $request->validate([

            'avatar' => 'required|image|mimes:jpeg,png,jpg,webp|max:5120',

        ]);



        $user = $request->user();



        $path = AvatarStorage::storeFromUpload(

            $request->file('avatar'),

            $user->profile_image,

        );



        $user->update(['profile_image' => $path]);

        $user->load('roles');



        $avatarUrl = MediaUrl::resolve($user->profile_image);



        return response()->json([

            'success' => true,

            'message' => 'Avatar updated successfully',

            'avatar_url' => $avatarUrl,

            'user' => new UserResource($user),

        ]);

    }

}

