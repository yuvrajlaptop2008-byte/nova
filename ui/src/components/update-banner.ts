// Control UI component renders update status and available-update actions.
import { html, nothing } from "lit";
import { property } from "lit/decorators.js";
import { NovaLightDomContentsElement } from "../lit/nova-element.ts";

type UpdateBannerProps = {
  statusBanner: { tone: "danger" | "warn" | "info"; text: string } | null;
};

class UpdateBanner extends NovaLightDomContentsElement {
  @property({ attribute: false }) props?: UpdateBannerProps;

  override render() {
    const props = this.props;
    if (!props) {
      return nothing;
    }
    return html`
      ${props.statusBanner
        ? html`<div class="callout ${props.statusBanner.tone}" role="alert">
            ${props.statusBanner.text}
          </div>`
        : nothing}
    `;
  }
}

if (!customElements.get("nova-update-banner")) {
  customElements.define("nova-update-banner", UpdateBanner);
}
