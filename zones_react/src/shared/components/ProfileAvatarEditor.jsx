import { useRef, useState, useEffect } from "react";
import { Camera, Trash2 } from "lucide-react";
import UserAvatar from "./UserAvatar";
import AvatarCropModal from "./AvatarCropModal";
import {
  deleteProfileAvatar,
  uploadProfileAvatar,
} from "../api/profileAvatarApi";
import {
  AVATAR_ACCEPT,
  readFileAsDataUrl,
  validateAvatarFile,
} from "../utils/avatarCanvas";
import { zonesToastError, zonesToastSuccess } from "../utils/zonesAlerts";

/**
 * Avatar picker with circular crop modal + upload/remove — syncs session via profileAvatarApi.
 */
export default function ProfileAvatarEditor({
  avatarUrl = "",
  fullName = "",
  size = "lg",
  onAvatarChange,
  useApi = true,
  onLocalAvatar,
}) {
  const fileRef = useRef(null);
  const [uploading, setUploading] = useState(false);
  const [localUrl, setLocalUrl] = useState(avatarUrl);
  const [cropOpen, setCropOpen] = useState(false);
  const [pendingFile, setPendingFile] = useState(null);

  useEffect(() => {
    setLocalUrl(avatarUrl);
  }, [avatarUrl]);

  const displayUrl = localUrl || avatarUrl;

  const closeCropModal = () => {
    if (uploading) return;
    setCropOpen(false);
    setPendingFile(null);
    if (fileRef.current) fileRef.current.value = "";
  };

  const handleFileSelected = (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;

    const validationError = validateAvatarFile(file);
    if (validationError) {
      zonesToastError(validationError);
      return;
    }

    setPendingFile(file);
    setCropOpen(true);
  };

  const handleCroppedConfirm = async (croppedFile) => {
    if (!useApi) {
      try {
        const dataUrl = await readFileAsDataUrl(croppedFile);
        setLocalUrl(dataUrl);
        onAvatarChange?.(dataUrl);
        onLocalAvatar?.(dataUrl);
        zonesToastSuccess("تم تحديث الصورة");
        closeCropModal();
      } catch {
        zonesToastError("تعذّر معالجة الصورة");
      }
      return;
    }

    setUploading(true);
    const result = await uploadProfileAvatar(croppedFile);
    setUploading(false);

    if (!result.ok) {
      zonesToastError(result.error || "تعذّر رفع الصورة");
      return;
    }

    const url = result.avatarUrl || "";
    setLocalUrl(url);
    onAvatarChange?.(url);
    zonesToastSuccess("تم تحديث الصورة بنجاح");
    closeCropModal();
  };

  const handleRemove = async () => {
    if (!useApi) {
      setLocalUrl("");
      onAvatarChange?.("");
      onLocalAvatar?.("");
      zonesToastSuccess("تم حذف الصورة");
      return;
    }

    setUploading(true);
    const result = await deleteProfileAvatar();
    setUploading(false);

    if (!result.ok) {
      zonesToastError(result.error || "تعذّر حذف الصورة");
      return;
    }

    setLocalUrl("");
    onAvatarChange?.("");
    zonesToastSuccess("تم حذف الصورة");
  };

  const dimension = size === "lg" ? "h-24 w-24" : "h-16 w-16";

  return (
    <>
      <div className="flex flex-col items-center gap-3">
        <div className={`relative ${dimension}`}>
          <UserAvatar src={displayUrl} name={fullName} size={size} />
          <button
            type="button"
            disabled={uploading}
            onClick={() => fileRef.current?.click()}
            className="absolute bottom-0 left-0 flex h-7 w-7 items-center justify-center rounded-full border-2 border-white bg-[#6B5478] text-white shadow disabled:opacity-60 dark:border-gray-900"
            aria-label="تغيير الصورة"
          >
            <Camera size={13} />
          </button>
          <input
            ref={fileRef}
            type="file"
            accept={AVATAR_ACCEPT}
            onChange={handleFileSelected}
            className="hidden"
          />
        </div>

        <div className="flex flex-wrap items-center justify-center gap-2">
          <button
            type="button"
            disabled={uploading}
            onClick={() => fileRef.current?.click()}
            className="rounded-xl border border-gray-300 px-3 py-1.5 text-[11px] font-bold text-gray-700 transition hover:bg-gray-50 disabled:opacity-60 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-gray-800"
          >
            {uploading ? "جاري الرفع..." : "تغيير الصورة"}
          </button>
          {displayUrl ? (
            <button
              type="button"
              disabled={uploading}
              onClick={handleRemove}
              className="flex items-center gap-1 rounded-xl border border-red-200 px-3 py-1.5 text-[11px] font-bold text-red-600 transition hover:bg-red-50 disabled:opacity-60 dark:border-red-900/40 dark:text-red-400 dark:hover:bg-red-950/30"
            >
              <Trash2 size={12} /> حذف الصورة
            </button>
          ) : null}
        </div>
      </div>

      <AvatarCropModal
        open={cropOpen}
        imageFile={pendingFile}
        onClose={closeCropModal}
        onConfirm={handleCroppedConfirm}
        uploading={uploading}
      />
    </>
  );
}
