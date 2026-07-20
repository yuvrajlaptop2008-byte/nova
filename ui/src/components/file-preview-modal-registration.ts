import { NovaFilePreviewModal } from "./file-preview-modal.ts";

if (!customElements.get("nova-file-preview-modal")) {
  customElements.define("nova-file-preview-modal", NovaFilePreviewModal);
}
