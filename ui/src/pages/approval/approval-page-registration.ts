import { ApprovalPage } from "./approval-page.ts";

if (!customElements.get("nova-approval-page")) {
  customElements.define("nova-approval-page", ApprovalPage);
}
