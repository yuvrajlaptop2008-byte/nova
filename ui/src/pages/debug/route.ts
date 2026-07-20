import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "debug",
  path: "/debug",
  component: () =>
    import("./debug-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-debug-page></nova-debug-page>`,
    })),
});
