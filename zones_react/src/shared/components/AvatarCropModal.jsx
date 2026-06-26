import { useEffect, useRef, useState } from "react";
import AvatarEditor from "react-avatar-editor";
import { Loader2 } from "lucide-react";
import AdminModal from "../../features/devices-packages/components/AdminModal";
import { canvasToAvatarFile } from "../utils/avatarCanvas";

/**
 * Dark-mode modal with circular crop mask, zoom slider, and optimized JPEG export.
 */
export default function AvatarCropModal({
  open,
  imageFile,
  onClose,
  onConfirm,
  uploading = false,
}) {
  const editorRef = useRef(null);
  const [scale, setScale] = useState(1);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (open) setScale(1);
  }, [open, imageFile]);

  const busy = uploading || saving;

  const handleApply = async () => {
    if (!editorRef.current || busy) return;
    setSaving(true);
    try {
      const source = editorRef.current.getImageScaledToCanvas();
      const file = await canvasToAvatarFile(source);
      await onConfirm(file);
    } finally {
      setSaving(false);
    }
  };

  return (
    <AdminModal
      open={open}
      onClose={() => {
        if (!busy) onClose();
      }}
      title="تعديل الصورة"
    >
      <div className="relative mt-4 space-y-5">
        {busy ? (
          <div className="absolute inset-0 z-10 flex items-center justify-center rounded-xl bg-gray-900/60 backdrop-blur-[1px]">
            <Loader2 className="h-8 w-8 animate-spin text-[#c4a8d4]" aria-hidden />
          </div>
        ) : null}

        <p className="text-center text-[11px] leading-relaxed text-gray-500 dark:text-gray-400">
          حرّك الصورة وكبّرها داخل الدائرة، ثم اضغط «حفظ وتطبيق».
        </p>

        <div className="flex justify-center rounded-2xl border border-gray-200 bg-[#14141f] p-4 dark:border-gray-700">
          {imageFile ? (
            <AvatarEditor
              ref={editorRef}
              image={imageFile}
              width={250}
              height={250}
              border={50}
              borderRadius={125}
              scale={scale}
              rotate={0}
              backgroundColor="#14141f"
              color={[107, 84, 120, 0.55]}
            />
          ) : null}
        </div>

        <div className="space-y-2 px-1">
          <div className="flex items-center justify-between text-[11px] font-bold text-gray-500 dark:text-gray-400">
            <span>تكبير</span>
            <span dir="ltr">{scale.toFixed(2)}×</span>
          </div>
          <input
            type="range"
            min={1}
            max={2}
            step={0.01}
            value={scale}
            disabled={busy}
            onChange={(e) => setScale(Number(e.target.value))}
            className="h-2 w-full cursor-pointer appearance-none rounded-full bg-gray-200 accent-[#6B5478] disabled:opacity-50 dark:bg-gray-700"
            aria-label="تكبير الصورة"
          />
        </div>

        <div className="flex flex-wrap justify-end gap-2 border-t border-gray-100 pt-4 dark:border-gray-800">
          <button
            type="button"
            disabled={busy}
            onClick={onClose}
            className="rounded-xl border border-gray-300 px-4 py-2 text-xs font-bold text-gray-700 transition hover:bg-gray-50 disabled:opacity-60 dark:border-gray-600 dark:text-gray-200 dark:hover:bg-gray-800"
          >
            إلغاء
          </button>
          <button
            type="button"
            disabled={busy || !imageFile}
            onClick={handleApply}
            className="flex items-center gap-2 rounded-xl bg-[#6B5478] px-4 py-2 text-xs font-bold text-white transition hover:bg-[#5a4665] disabled:opacity-60"
          >
            {busy ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                جاري الحفظ...
              </>
            ) : (
              "حفظ وتطبيق"
            )}
          </button>
        </div>
      </div>
    </AdminModal>
  );
}
