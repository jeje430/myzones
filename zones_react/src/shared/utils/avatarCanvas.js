const OUTPUT_SIZE = 400;

/**
 * Converts the AvatarEditor canvas to an optimized JPEG File (~400×400).
 */
export function canvasToAvatarFile(sourceCanvas) {
  return new Promise((resolve, reject) => {
    if (!sourceCanvas) {
      reject(new Error("Missing canvas"));
      return;
    }

    const canvas = document.createElement("canvas");
    canvas.width = OUTPUT_SIZE;
    canvas.height = OUTPUT_SIZE;
    const ctx = canvas.getContext("2d");
    if (!ctx) {
      reject(new Error("Canvas unavailable"));
      return;
    }

    ctx.drawImage(sourceCanvas, 0, 0, OUTPUT_SIZE, OUTPUT_SIZE);
    canvas.toBlob(
      (blob) => {
        if (!blob) {
          reject(new Error("Failed to process image"));
          return;
        }
        resolve(new File([blob], "avatar.jpg", { type: "image/jpeg" }));
      },
      "image/jpeg",
      0.85,
    );
  });
}

export function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === "string") resolve(reader.result);
      else reject(new Error("Failed to read image"));
    };
    reader.onerror = () => reject(new Error("Failed to read image"));
    reader.readAsDataURL(file);
  });
}

export const AVATAR_ACCEPT = "image/jpeg,image/png,image/jpg,image/webp";
export const AVATAR_MAX_BYTES = 5 * 1024 * 1024;

export function validateAvatarFile(file) {
  if (!file) return "لم يتم اختيار صورة.";
  if (file.size > AVATAR_MAX_BYTES) {
    return "حجم الصورة يجب ألا يتجاوز 5 ميجابايت.";
  }
  const type = (file.type || "").toLowerCase();
  if (type && !["image/jpeg", "image/png", "image/jpg", "image/webp"].includes(type)) {
    return "نوع الصورة غير مدعوم. استخدم JPG أو PNG أو WebP.";
  }
  return null;
}
