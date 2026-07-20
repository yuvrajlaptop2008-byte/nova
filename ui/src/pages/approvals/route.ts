import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "approvals",
  path: "/settings/approvals",
  component: () =>
    import("./approvals-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-approvals-page></nova-approvals-page>`,
    })),
});
