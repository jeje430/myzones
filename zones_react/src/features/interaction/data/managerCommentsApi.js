import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { resolveMediaUrl } from "../../../shared/utils/resolveMediaUrl";

function mapApiComment(row) {
  const reply = row.manager_reply;
  const user = row.user;
  const profileImage = resolveMediaUrl(
    row.profile_image || user?.profile_image || user?.profileImage || "",
  );
  const customerName =
    row.customer_name || user?.full_name || user?.name || "زبون";

  return {
    id: row.id,
    customerName,
    text: row.body || "",
    createdAt: row.submitted_at ? Date.parse(row.submitted_at) : Date.now(),
    editedAt: row.edited_at ? Date.parse(row.edited_at) : null,
    profileImage: profileImage || null,
    user: user
      ? {
          id: user.id,
          name: user.full_name || user.name || customerName,
          profileImage,
        }
      : null,
    managerReply: reply
      ? {
          id: reply.id,
          text: reply.body || "",
          managerName:
            reply.manager_name ||
            reply.user?.full_name ||
            reply.user?.name ||
            "مدير الصالة",
          repliedAt: reply.replied_at ? Date.parse(reply.replied_at) : Date.now(),
          profileImage: resolveMediaUrl(
            reply.profile_image || reply.user?.profile_image || "",
          ) || null,
        }
      : null,
  };
}

export async function fetchManagerComments() {
  try {
    const { data } = await apiClient.get("/manager/comments");
    const comments = (data.comments || []).map(mapApiComment);
    return {
      ok: true,
      comments,
      stats: data.stats || { total: comments.length, pending: 0, replied: 0 },
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), comments: [] };
  }
}

export async function replyToManagerComment(commentId, body) {
  try {
    const { data } = await apiClient.post(`/manager/comments/${commentId}/reply`, {
      body,
    });
    return {
      ok: true,
      comment: data.comment ? mapApiComment(data.comment) : null,
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function deleteManagerComment(commentId) {
  try {
    const { data } = await apiClient.delete(`/manager/comments/${commentId}`);
    return { ok: true, message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
