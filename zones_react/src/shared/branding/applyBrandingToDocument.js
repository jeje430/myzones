import { DEFAULT_DOCUMENT_TITLE } from "./brandingConstants";

function resolveFaviconType(href) {
  if (href.endsWith(".svg")) return "image/svg+xml";
  if (href.endsWith(".png")) return "image/png";
  if (href.endsWith(".jpg") || href.endsWith(".jpeg")) return "image/jpeg";
  return "image/png";
}

export function applyBrandingToDocument({ platformName, logoSrc }) {
  const name = platformName?.trim() || DEFAULT_DOCUMENT_TITLE;
  document.title = name === DEFAULT_DOCUMENT_TITLE ? DEFAULT_DOCUMENT_TITLE : `${name} | ZONES`;

  let link = document.querySelector("link[data-zones-branding-favicon='true']");
  if (!link) {
    link = document.createElement("link");
    link.rel = "icon";
    link.setAttribute("data-zones-branding-favicon", "true");
    document.head.appendChild(link);
  }

  link.href = logoSrc;
  link.type = resolveFaviconType(logoSrc);
}
