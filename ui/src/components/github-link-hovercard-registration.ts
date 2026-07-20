import { GitHubLinkHovercardProvider } from "./github-link-hovercard.ts";

if (!customElements.get("nova-github-link-hovercard-provider")) {
  customElements.define("nova-github-link-hovercard-provider", GitHubLinkHovercardProvider);
}
