import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "apps",
  path: "/apps",
  component: () =>
    import("./apps-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-apps-page></nova-apps-page>`,
    })),
});
