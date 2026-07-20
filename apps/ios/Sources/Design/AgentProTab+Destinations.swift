import NovaKit
import NovaProtocol
import SwiftUI

extension AgentProTab {
    @ViewBuilder
    func destination(for route: AgentRoute) -> some View {
        switch route {
        case .agents:
            self.agentsDestination
        case .skills:
            self.skillsDestination
        case .instances:
            self.instancesDestination
        case .cron:
            self.cronDestination
        case .usage:
            self.usageDestination
        case .dreaming:
            self.dreamingDestination
        case .files:
            self.filesDestination
        }
    }

    var filesDestination: some View {
        AgentWorkspaceFilesScreen(
            agentId: self.activeAgentID,
            headerSidebarAction: self.directHeaderSidebarAction(for: .files))
    }

    var agentsDestination: some View {
        List {
            Section {
                if self.filteredAgents.isEmpty {
                    self.emptyAgentsRow
                } else {
                    ForEach(self.filteredAgents, id: \.id) { agent in
                        self.agentRow(agent)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(self.headerTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: self.$agentSearchText, prompt: "Search agents")
        .refreshable {
            await self.refreshOverview(force: true)
        }
        .font(NovaType.body)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                self.agentFilterMenu
                self.gatewayToolbarButton
            }
            if let headerSidebarAction {
                ToolbarItem(placement: .topBarLeading) {
                    NovaSidebarHeaderLeadingSlot(action: headerSidebarAction)
                }
            }
        }
    }

    var skillsDestination: some View {
        ZStack {
            NovaProBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    self.detailSummaryCard(
                        icon: "sparkles",
                        title: "Skills",
                        value: self.skillsValue,
                        detail: self.skillsDetail,
                        color: self.gatewayConnected ? NovaBrand.accent : .secondary)
                    self.skillsPolicyControls
                    self.skillsFilterField
                    self.clawHubSearchCard
                    self.skillsList
                }
                .padding(.vertical, 18)
                .font(NovaType.body)
            }
            .refreshable {
                await self.refreshOverview(force: true)
            }
            .safeAreaPadding(.bottom, NovaProMetric.bottomScrollInset)
        }
        .navigationTitle("Skills")
        .navigationBarTitleDisplayMode(.inline)
    }

    var instancesDestination: some View {
        AgentProNodesDestination(
            headerSidebarAction: self.directHeaderSidebarAction(for: .instances),
            overview: self.overview,
            gatewayConnected: self.gatewayConnected,
            agentCount: self.appModel.gatewayAgents.count,
            instancesValue: self.instancesValue,
            instancesDetail: self.instancesDetail,
            instancesColor: self.instancesColor,
            refresh: {
                await self.refreshOverview(force: true)
            })
    }

    var cronDestination: some View {
        ZStack {
            NovaProBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    self.directHeader(
                        for: .cron,
                        title: "Automations",
                        subtitle: self.cronDetail)
                    self.detailSummaryCard(
                        icon: "clock.arrow.circlepath",
                        title: "Automations",
                        value: self.cronValue,
                        detail: self.cronDetail,
                        color: self.cronColor)
                    self.cronStatusCard
                    self.cronJobsList(limit: nil)
                }
                .padding(.vertical, 18)
                .font(NovaType.body)
            }
            .refreshable {
                await self.refreshOverview(force: true)
            }
            .safeAreaPadding(.bottom, NovaProMetric.bottomScrollInset)
        }
        .navigationTitle("Automations")
        .navigationBarTitleDisplayMode(.inline)
    }

    var usageDestination: some View {
        ZStack {
            NovaProBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    self.directHeader(
                        for: .usage,
                        title: "Usage",
                        subtitle: self.usageDetail)
                    self.detailSummaryCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Usage",
                        value: self.usageValue,
                        detail: self.usageDetail,
                        color: self.gatewayConnected ? NovaBrand.accent : .secondary)
                    self.usageTotalsCard
                    self.usageDailyList
                }
                .padding(.vertical, 18)
                .font(NovaType.body)
            }
            .refreshable {
                await self.refreshOverview(force: true)
            }
            .safeAreaPadding(.bottom, NovaProMetric.bottomScrollInset)
        }
        .navigationTitle("Usage")
        .navigationBarTitleDisplayMode(.inline)
    }

    var dreamingDestination: some View {
        AgentProDreamingDestination(
            headerSidebarAction: self.directHeaderSidebarAction(for: .dreaming),
            overview: self.overview,
            gatewayConnected: self.gatewayConnected,
            overviewLoading: self.overviewLoading,
            dreamingValue: self.dreamingValue,
            dreamingDetail: self.dreamingDetail,
            dreamingColor: self.dreamingColor,
            refresh: {
                await self.refreshOverview(force: true)
            })
    }

    @ViewBuilder
    func directHeader(for route: AgentRoute, title: String, subtitle: String) -> some View {
        if let headerSidebarAction = self.directHeaderSidebarAction(for: route) {
            NovaAdaptiveHeaderRow(
                title: .localized(title),
                subtitle: .localized(subtitle),
                titleFont: NovaType.title3SemiBold,
                subtitleFont: NovaType.subheadMedium)
            {
                NovaSidebarHeaderLeadingSlot(action: headerSidebarAction)
            } accessory: {
                EmptyView()
            }
            .padding(.horizontal, NovaProMetric.pagePadding)
        }
    }

    func directHeaderSidebarAction(for route: AgentRoute) -> NovaSidebarHeaderAction? {
        self.directRoute == route ? self.headerSidebarAction : nil
    }

    func detailSummaryCard(
        icon: String,
        title: String,
        value: String,
        detail: String,
        color: Color) -> some View
    {
        ProCard(radius: AgentLayout.cardRadius) {
            HStack(spacing: 12) {
                ProIconBadge(systemName: icon, color: color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(NovaType.headline)
                    Text(detail)
                        .font(NovaType.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                ProValuePill(value: value, color: color)
            }
        }
        .padding(.horizontal, NovaProMetric.pagePadding)
    }
}
