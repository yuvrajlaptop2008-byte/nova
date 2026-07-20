import Observation
import NovaChatUI
import SwiftUI

@MainActor
struct ChatModelControlsMenuItems: View {
    @Bindable var viewModel: NovaChatViewModel

    var body: some View {
        if self.viewModel.showsModelPicker {
            self.modelPicker
        }
        if self.viewModel.showsThinkingPicker {
            self.thinkingPicker
        }
        if self.viewModel.selectedModelSupportsFastMode {
            self.fastModePicker
        }
        self.verbosityPicker
    }

    private var modelPicker: some View {
        let sections = self.viewModel.modelPickerSections
        return Picker(selection: Binding(
            get: { self.viewModel.modelSelectionID },
            set: { self.viewModel.selectModel($0) }))
        {
            Text(self.viewModel.defaultModelLabel)
                .font(NovaType.body)
                .tag(NovaChatViewModel.defaultModelSelectionID)
            if !sections.pinned.isEmpty {
                Section("Pinned") {
                    self.modelOptions(sections.pinned)
                }
            }
            if !sections.recent.isEmpty {
                Section("Recent") {
                    self.modelOptions(sections.recent)
                }
            }
            ForEach(sections.providers) { provider in
                Section {
                    self.modelOptions(provider.models)
                } header: {
                    HStack(spacing: 4) {
                        Text(provider.displayName)
                            .font(NovaType.body)
                        if provider.isDefaultProvider {
                            Text("Default")
                                .font(NovaType.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } label: {
            Text("Model")
                .font(NovaType.body)
        }
        .disabled(self.viewModel.isUpdatingSessionSettings)
    }

    private var thinkingPicker: some View {
        Picker(selection: Binding(
            get: { self.viewModel.thinkingSelectionID },
            set: { self.viewModel.selectThinkingLevel($0) }))
        {
            Text("Default (inherited)")
                .font(NovaType.body)
                .tag(NovaChatViewModel.inheritedThinkingSelectionID)
            ForEach(self.viewModel.thinkingLevelOptions) { option in
                Text(verbatim: option.label)
                    .font(NovaType.body)
                    .tag(option.id)
            }
        } label: {
            Text("Thinking")
                .font(NovaType.body)
        }
        .disabled(self.viewModel.isUpdatingSessionSettings)
    }

    private var fastModePicker: some View {
        Picker(selection: Binding(
            get: { self.viewModel.fastModeSelectionID },
            set: { self.viewModel.selectFastMode($0) }))
        {
            Text("Default (inherited)")
                .font(NovaType.body)
                .tag(NovaChatViewModel.inheritedThinkingSelectionID)
            Text("On")
                .font(NovaType.body)
                .tag("on")
            Text("Off")
                .font(NovaType.body)
                .tag("off")
        } label: {
            Label {
                Text("Fast")
                    .font(NovaType.body)
            } icon: {
                Image(systemName: "bolt.fill")
            }
        }
        .disabled(self.viewModel.isUpdatingSessionSettings)
    }

    private var verbosityPicker: some View {
        Picker(selection: Binding(
            get: { self.viewModel.verboseLevel },
            set: { self.viewModel.selectVerboseLevel($0) }))
        {
            Text("Default (inherited)")
                .font(NovaType.body)
                .tag(NovaChatViewModel.inheritedThinkingSelectionID)
            Text("Off")
                .font(NovaType.body)
                .tag("off")
            Text("On")
                .font(NovaType.body)
                .tag("on")
            Text("Full")
                .font(NovaType.body)
                .tag("full")
        } label: {
            Text("Verbosity")
                .font(NovaType.body)
        }
        .disabled(self.viewModel.isUpdatingSessionSettings)
    }

    private func modelOptions(_ models: [NovaChatModelChoice]) -> some View {
        ForEach(models) { model in
            HStack(spacing: 4) {
                Text(model.displayLabel)
                    .font(NovaType.body)
                if self.viewModel.isDefaultModel(model) {
                    Text("Default")
                        .font(NovaType.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tag(model.selectionID)
        }
    }
}
