import NovaKit
import SwiftUI

extension AgentProTab {
    func detailMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(NovaType.caption2Medium)
                .foregroundStyle(.secondary)
            Text(value)
                .font(NovaType.subheadSemiBold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            Color.primary.opacity(0.055),
            in: RoundedRectangle(cornerRadius: NovaRadius.sm, style: .continuous))
    }

    func emptyDetailRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            ProIconBadge(systemName: icon, color: .secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(NovaType.subheadSemiBold)
                Text(detail)
                    .font(NovaType.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
        }
    }
}
