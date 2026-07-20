import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "cron",
  path: "/cron",
  component: () =>
    import("./cron-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-cron-page></nova-cron-page>`,
    })),
});
