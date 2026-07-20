import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "about",
  path: "/settings/about",
  component: () =>
    import("./about-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-about-page></nova-about-page>`,
    })),
});
