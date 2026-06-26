/**
 * Tournament cover image processing (React upload).
 *
 * Adjust display shape here — used by CreateTournamentModal before sending to Laravel.
 *
 * COVER_ASPECT     → width / height (16:9 = horizontal banner like Flutter cards)
 * COVER_OUTPUT_WIDTH → final pixel width sent to API (height computed from aspect)
 * COVER_JPEG_QUALITY → compression 0–1
 */

export const COVER_ASPECT = 16 / 9;
export const COVER_OUTPUT_WIDTH = 1200;
export const COVER_JPEG_QUALITY = 0.82;
export const COVER_MAX_FILE_BYTES = 12 * 1024 * 1024;

const COVER_OUTPUT_HEIGHT = Math.round(COVER_OUTPUT_WIDTH / COVER_ASPECT);

/**
 * Read file → center-crop to aspect → resize → JPEG data URL.
 * @param {File} file
 * @returns {Promise<string>}
 */
export async function processTournamentCoverFile(file) {
  if (!file?.type?.startsWith("image/")) {
    throw new Error("not-image");
  }

  const dataUrl = await readFileAsDataUrl(file);
  const img = await loadImage(dataUrl);

  const sourceW = img.naturalWidth;
  const sourceH = img.naturalHeight;
  if (!sourceW || !sourceH) {
    throw new Error("invalid-dimensions");
  }

  const sourceAspect = sourceW / sourceH;
  let cropW = sourceW;
  let cropH = sourceH;
  let cropX = 0;
  let cropY = 0;

  if (sourceAspect > COVER_ASPECT) {
    cropW = Math.round(sourceH * COVER_ASPECT);
    cropX = Math.round((sourceW - cropW) / 2);
  } else if (sourceAspect < COVER_ASPECT) {
    cropH = Math.round(sourceW / COVER_ASPECT);
    cropY = Math.round((sourceH - cropH) / 2);
  }

  const canvas = document.createElement("canvas");
  canvas.width = COVER_OUTPUT_WIDTH;
  canvas.height = COVER_OUTPUT_HEIGHT;
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    throw new Error("no-canvas");
  }

  ctx.drawImage(img, cropX, cropY, cropW, cropH, 0, 0, COVER_OUTPUT_WIDTH, COVER_OUTPUT_HEIGHT);

  return canvas.toDataURL("image/jpeg", COVER_JPEG_QUALITY);
}

function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error("load-failed"));
    image.src = src;
  });
}
