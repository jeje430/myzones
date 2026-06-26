<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\StationCommentResource;
use App\Models\StationComment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ManagerCommentController extends Controller
{
    use ResolvesManagerStation;

    public function index(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $comments = StationComment::query()
            ->where('station_id', $station->id)
            ->whereNull('parent_id')
            ->with([
                'user',
                'replies' => fn ($q) => $q->with('user')->oldest(),
            ])
            ->latest()
            ->get();

        return response()->json([
            'comments' => StationCommentResource::collection($comments)->resolve(),
            'stats' => [
                'total' => $comments->count(),
                'pending' => $comments->filter(fn ($c) => $c->replies->isEmpty())->count(),
                'replied' => $comments->filter(fn ($c) => $c->replies->isNotEmpty())->count(),
            ],
        ]);
    }

    public function reply(Request $request, StationComment $comment): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        abort_unless((int) $comment->station_id === (int) $station->id, 404);
        abort_unless($comment->parent_id === null, 422);

        $validated = $request->validate([
            'body' => 'required|string|min:1|max:2000',
        ]);

        $manager = $request->user();
        $body = trim($validated['body']);

        $existingReply = $comment->replies()->first();

        if ($existingReply) {
            $existingReply->update([
                'body' => $body,
                'user_id' => $manager->id,
                'edited_at' => now(),
            ]);
            $reply = $existingReply->fresh(['user']);
        } else {
            $reply = StationComment::create([
                'station_id' => $station->id,
                'user_id' => $manager->id,
                'parent_id' => $comment->id,
                'body' => $body,
            ]);
            $reply->load('user');
        }

        $comment->load(['user', 'replies.user']);

        return response()->json([
            'message' => $existingReply ? 'تم تحديث الرد بنجاح' : 'تم إرسال الرد بنجاح',
            'comment' => (new StationCommentResource($comment))->resolve(),
        ]);
    }

    public function destroy(Request $request, StationComment $comment): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        abort_unless((int) $comment->station_id === (int) $station->id, 404);
        abort_unless($comment->parent_id === null, 422);

        $comment->replies()->delete();
        $comment->delete();

        return response()->json([
            'message' => 'تم حذف التعليق بنجاح',
        ]);
    }
}
