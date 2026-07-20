import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "logs",
  path: "/logs",
  component: () =>
    import("./logs-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-logs-page></nova-logs-page>`,
    })),
});
