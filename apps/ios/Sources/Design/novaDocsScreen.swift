import SwiftUI

struct NovaDocsScreen: View {
    private let docsURL = URL(string: "https://docs.nova.ai")!
    private let gatewayURL = URL(string: "https://docs.nova.ai/gateway")!
    private let pairingURL = URL(string: "https://docs.nova.ai/channels/pairing")!
    let headerSidebarAction: NovaSidebarHeaderAction?
    let usesNativeNavigationChrome: Bool
    let gatewayAction: (() -> Void)?

    init(
        headerSidebarAction: NovaSidebarHeaderAction? = nil,
        usesNativeNavigationChrome: Bool = false,
        gatewayAction: (() -> Void)? = nil)
    {
        self.headerSidebarAction = headerSidebarAction
        self.usesNativeNavigationChrome = usesNativeNavigationChrome
        self.gatewayAction = gatewayAction
    }

    var body: some View {
        ZStack {
            NovaProBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !self.usesNativeNavigationChrome {
                        self.headerCard
                    }
                    self.linkCard
                }
                .padding(.vertical, 18)
                .font(NovaType.body)
            }
        }
        .navigationTitle("Docs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(self.usesNativeNavigationChrome ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if self.usesNativeNavigationChrome, let gatewayAction {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: gatewayAction) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(NovaType.subheadSemiBold)
                    }
                    .accessibilityLabel("Gateway settings")
                }
            }
            if self.usesNativeNavigationChrome, let headerSidebarAction {
                ToolbarItem(placement: .topBarLeading) {
                    NovaSidebarRevealButton(action: headerSidebarAction)
                }
            }
        }
    }

    private var headerCard: some View {
        ProCard(radius: NovaProMetric.cardRadius) {
            NovaAdaptiveHeaderRow(
                title: "Docs",
                subtitle: "Gateway setup, pairing, channels, and mobile node reference.",
                titleFont: NovaType.headline,
                subtitleFont: NovaType.caption)
            {
                HStack(spacing: 10) {
                    if let headerSidebarAction {
                        NovaSidebarHeaderLeadingSlot(action: headerSidebarAction)
                    }
                    ProIconBadge(systemName: "book", color: NovaBrand.accent)
                }
            } accessory: {
                self.gatewayPill
            }
        }
        .padding(.horizontal, NovaProMetric.pagePadding)
    }

    @ViewBuilder
    private var gatewayPill: some View {
        if let gatewayAction {
            Button(action: gatewayAction) {
                NovaGatewayCompactPill()
            }
            .buttonBorderShape(.capsule)
            .novaGlassButton()
            .accessibilityHint("Opens Settings / Gateway")
        } else {
            NovaGatewayCompactPill()
        }
    }

    private var linkCard: some View {
        ProCard(padding: 0, radius: NovaProMetric.cardRadius) {
            VStack(spacing: 0) {
                self.docsLinkRow(
                    title: "Docs Home",
                    detail: "Browse the current Nova reference.",
                    icon: "book",
                    url: self.docsURL)
                Divider().padding(.leading, 58)
                self.docsLinkRow(
                    title: "Gateway",
                    detail: "Connection, auth, and diagnostics.",
                    icon: "network",
                    url: self.gatewayURL)
                Divider().padding(.leading, 58)
                self.docsLinkRow(
                    title: "Pairing",
                    detail: "Mobile setup codes, QR, and node approval.",
                    icon: "qrcode",
                    url: self.pairingURL)
            }
        }
        .padding(.horizontal, NovaProMetric.pagePadding)
    }

    private func docsLinkRow(title: String, detail: String, icon: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                ProIconBadge(systemName: icon, color: NovaBrand.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(NovaType.subheadSemiBold)
                    Text(detail)
                        .font(NovaType.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(NovaType.captionBold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
