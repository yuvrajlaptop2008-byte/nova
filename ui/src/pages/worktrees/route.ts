import { definePage } from "@nova/uirouter";
import { html } from "lit";

export const page = definePage({
  id: "worktrees",
  path: "/worktrees",
  aliases: ["/settings/worktrees"],
  component: () =>
    import("./worktrees-page.ts").then(() => ({
      header: true,
      render: () => html`<nova-worktrees-page></nova-worktrees-page>`,
    })),
});
