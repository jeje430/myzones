<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\StationCommentResource;
use App\Models\Station;
use App\Models\StationComment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StationCommentController extends Controller
{
    public function index(Request $request, Station $station): JsonResponse
    {
        abort_unless(
            $station->is_published && $station->is_active && $station->manager_id !== null,
            404
        );

        $perPage = min(max((int) $request->query('per_page', 10), 1), 50);
        $page = max((int) $request->query('page', 1), 1);

        $paginator = $station->comments()
            ->whereNull('parent_id')
            ->with([
                'user',
                'replies' => fn ($q) => $q->with('user')->oldest(),
            ])
            ->latest()
            ->paginate(perPage: $perPage, page: $page);

        return response()->json([
            'comments' => StationCommentResource::collection($paginator->getCollection())->resolve(),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    public function store(Request $request, Station $station): JsonResponse
    {
        abort_unless(
            $station->is_published && $station->is_active && $station->manager_id !== null,
            404
        );

        $user = $request->user();
        abort_unless($user !== null, 401);
        abort_unless($user->hasRole('customer'), 403);

        $validated = $request->validate([
            'body' => 'required|string|min:1|max:2000',
        ]);

        $comment = StationComment::create([
            'station_id' => $station->id,
            'user_id' => $user->id,
            'body' => trim($validated['body']),
        ]);

        $comment->load(['user', 'replies.user']);

        return response()->json([
            'message' => 'تم إرسال التعليق بنجاح',
            'comment' => (new StationCommentResource($comment))->resolve(),
        ], 201);
    }

    public function update(Request $request, Station $station, StationComment $comment): JsonResponse
    {
        abort_unless(
            $station->is_published && $station->is_active && $station->manager_id !== null,
            404
        );

        abort_unless((int) $comment->station_id === (int) $station->id, 404);
        abort_unless($comment->parent_id === null, 422);

        $user = $request->user();
        abort_unless($user !== null, 401);
        abort_unless((int) $comment->user_id === (int) $user->id, 403);

        $validated = $request->validate([
            'body' => 'required|string|min:1|max:2000',
        ]);

        $comment->update([
            'body' => trim($validated['body']),
            'edited_at' => now(),
        ]);

        $comment->load(['user', 'replies.user']);

        return response()->json([
            'message' => 'تم تحديث التعليق بنجاح',
            'comment' => (new StationCommentResource($comment))->resolve(),
        ]);
    }
}
