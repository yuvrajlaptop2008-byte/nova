import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "connection",
  path: "/settings/connection",
  component: () =>
    import("./connection-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-connection-page></nova-connection-page>`,
    })),
});
