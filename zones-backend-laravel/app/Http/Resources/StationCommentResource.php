<?php



namespace App\Http\Resources;



use App\Support\MediaUrl;

use Illuminate\Http\Request;

use Illuminate\Http\Resources\Json\JsonResource;



class StationCommentResource extends JsonResource

{

    public function toArray(Request $request): array

    {

        $author = $this->relationLoaded('user') ? $this->user : null;

        $authUserId = $request->user()?->id;

        $reply = $this->relationLoaded('replies') ? $this->replies->first() : null;

        $replyAuthor = $reply && $reply->relationLoaded('user') ? $reply->user : null;



        return [

            'id' => $this->id,

            'body' => $this->body,

            'customer_name' => $author?->full_name ?? 'زبون',

            'profile_image' => MediaUrl::resolve($author?->profile_image),

            'user' => $author ? [

                'id' => $author->id,

                'name' => $author->full_name,

                'full_name' => $author->full_name,

                'profile_image' => MediaUrl::resolve($author->profile_image),

            ] : null,

            'submitted_at' => $this->created_at?->toIso8601String(),

            'edited_at' => $this->edited_at?->toIso8601String(),

            'updated_at' => ($this->edited_at ?? $this->created_at)?->toIso8601String(),

            'can_edit' => $authUserId !== null && (int) $this->user_id === (int) $authUserId && $this->parent_id === null,

            'is_reply' => $this->parent_id !== null,

            'manager_reply' => $reply ? [

                'id' => $reply->id,

                'body' => $reply->body,

                'manager_name' => $replyAuthor?->full_name ?? 'مدير الصالة',

                'profile_image' => MediaUrl::resolve($replyAuthor?->profile_image),

                'replied_at' => $reply->created_at?->toIso8601String(),

                'user' => $replyAuthor ? [

                    'id' => $replyAuthor->id,

                    'name' => $replyAuthor->full_name,

                    'full_name' => $replyAuthor->full_name,

                    'profile_image' => MediaUrl::resolve($replyAuthor->profile_image),

                ] : null,

            ] : null,

        ];

    }

}


