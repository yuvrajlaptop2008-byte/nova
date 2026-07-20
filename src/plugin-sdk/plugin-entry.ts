// Plugin entry contracts define the manifest-facing hooks implemented by plugin packages.
import type { NovaConfig } from "../config/types.nova.js";
import { emptyPluginConfigSchema } from "../plugins/config-schema.js";
import type {
  AgentHarness as _AgentHarness,
  AgentPromptGuidance as _AgentPromptGuidance,
  AgentPromptGuidanceEntry as _AgentPromptGuidanceEntry,
  AgentPromptSurfaceKind as _AgentPromptSurfaceKind,
  AnyAgentTool as _AnyAgentTool,
  MediaUnderstandingProviderPlugin as _MediaUnderstandingProviderPlugin,
  MigrationApplyResult as _MigrationApplyResult,
  MigrationDetection as _MigrationDetection,
  MigrationItem as _MigrationItem,
  MigrationPlan as _MigrationPlan,
  MigrationProviderContext as _MigrationProviderContext,
  MigrationProviderPlugin as _MigrationProviderPlugin,
  ProviderPlugin as _ProviderPlugin,
  MigrationSummary as _MigrationSummary,
  NovaGatewayDiscoveryAdvertiseContext as _NovaGatewayDiscoveryAdvertiseContext,
  NovaGatewayDiscoveryService as _NovaGatewayDiscoveryService,
  NovaPluginApi as _NovaPluginApi,
  NovaPluginCommandDefinition as _NovaPluginCommandDefinition,
  NovaPluginConfigSchema as _NovaPluginConfigSchema,
  NovaPluginDefinition as _NovaPluginDefinition,
  NovaPluginHttpRouteHandler as _NovaPluginHttpRouteHandler,
  NovaPluginNodeHostCommand as _NovaPluginNodeHostCommand,
  NovaPluginNodeHostCommandAvailabilityContext as _NovaPluginNodeHostCommandAvailabilityContext,
  NovaPluginNodeInvokePolicy as _NovaPluginNodeInvokePolicy,
  NovaPluginNodeInvokePolicyContext as _NovaPluginNodeInvokePolicyContext,
  NovaPluginNodeInvokePolicyResult as _NovaPluginNodeInvokePolicyResult,
  NovaPluginReloadRegistration as _NovaPluginReloadRegistration,
  NovaPluginSecurityAuditCollector as _NovaPluginSecurityAuditCollector,
  NovaPluginSecurityAuditContext as _NovaPluginSecurityAuditContext,
  NovaPluginService as _NovaPluginService,
  NovaPluginServiceContext as _NovaPluginServiceContext,
  NovaPluginToolContext as _NovaPluginToolContext,
  NovaPluginToolFactory as _NovaPluginToolFactory,
  PluginAgentEventEmitParams as _PluginAgentEventEmitParams,
  PluginAgentEventEmitResult as _PluginAgentEventEmitResult,
  PluginAgentEventSubscriptionRegistration as _PluginAgentEventSubscriptionRegistration,
  PluginAgentTurnPrepareEvent as _PluginAgentTurnPrepareEvent,
  PluginAgentTurnPrepareResult as _PluginAgentTurnPrepareResult,
  PluginCommandContext as _PluginCommandContext,
  PluginCommandResult as _PluginCommandResult,
  PluginControlUiDescriptor as _PluginControlUiDescriptor,
  PluginHeartbeatPromptContributionEvent as _PluginHeartbeatPromptContributionEvent,
  PluginHeartbeatPromptContributionResult as _PluginHeartbeatPromptContributionResult,
  PluginJsonValue as _PluginJsonValue,
  PluginLogger as _PluginLogger,
  PluginNextTurnInjection as _PluginNextTurnInjection,
  PluginNextTurnInjectionEnqueueResult as _PluginNextTurnInjectionEnqueueResult,
  PluginNextTurnInjectionRecord as _PluginNextTurnInjectionRecord,
  PluginRunContextGetParams as _PluginRunContextGetParams,
  PluginRunContextPatch as _PluginRunContextPatch,
  PluginRuntimeLifecycleRegistration as _PluginRuntimeLifecycleRegistration,
  PluginSessionActionContext as _PluginSessionActionContext,
  PluginSessionActionRegistration as _PluginSessionActionRegistration,
  PluginSessionActionResult as _PluginSessionActionResult,
  PluginSessionAttachmentParams as _PluginSessionAttachmentParams,
  PluginSessionAttachmentResult as _PluginSessionAttachmentResult,
  PluginSessionExtensionProjection as _PluginSessionExtensionProjection,
  PluginSessionExtensionRegistration as _PluginSessionExtensionRegistration,
  PluginSessionSchedulerJobHandle as _PluginSessionSchedulerJobHandle,
  PluginSessionSchedulerJobRegistration as _PluginSessionSchedulerJobRegistration,
  PluginSessionTurnScheduleParams as _PluginSessionTurnScheduleParams,
  PluginSessionTurnUnscheduleByTagParams as _PluginSessionTurnUnscheduleByTagParams,
  PluginSessionTurnUnscheduleByTagResult as _PluginSessionTurnUnscheduleByTagResult,
  PluginToolMetadataRegistration as _PluginToolMetadataRegistration,
  PluginTrustedToolPolicyRegistration as _PluginTrustedToolPolicyRegistration,
  ProviderApplyConfigDefaultsContext as _ProviderApplyConfigDefaultsContext,
  ProviderAugmentModelCatalogContext as _ProviderAugmentModelCatalogContext,
  ProviderAuthContext as _ProviderAuthContext,
  ProviderAuthDoctorHintContext as _ProviderAuthDoctorHintContext,
  ProviderAuthMethod as _ProviderAuthMethod,
  ProviderAuthMethodNonInteractiveContext as _ProviderAuthMethodNonInteractiveContext,
  ProviderAppGuidedSetup as _ProviderAppGuidedSetup,
  ProviderAppGuidedSetupCandidate as _ProviderAppGuidedSetupCandidate,
  ProviderAppGuidedSetupContext as _ProviderAppGuidedSetupContext,
  ProviderAuthResult as _ProviderAuthResult,
  ProviderBuildMissingAuthMessageContext as _ProviderBuildMissingAuthMessageContext,
  ProviderBuildUnknownModelHintContext as _ProviderBuildUnknownModelHintContext,
  ProviderBuiltInModelSuppressionContext as _ProviderBuiltInModelSuppressionContext,
  ProviderBuiltInModelSuppressionResult as _ProviderBuiltInModelSuppressionResult,
  ProviderCacheTtlEligibilityContext as _ProviderCacheTtlEligibilityContext,
  ProviderCatalogContext as _ProviderCatalogContext,
  ProviderCatalogResult as _ProviderCatalogResult,
  ProviderDefaultThinkingPolicyContext as _ProviderDefaultThinkingPolicyContext,
  ProviderDeferSyntheticProfileAuthContext as _ProviderDeferSyntheticProfileAuthContext,
  ProviderFailoverErrorContext as _ProviderFailoverErrorContext,
  ProviderFetchUsageSnapshotContext as _ProviderFetchUsageSnapshotContext,
  ProviderModernModelPolicyContext as _ProviderModernModelPolicyContext,
  ProviderNormalizeConfigContext as _ProviderNormalizeConfigContext,
  ProviderNormalizeModelIdContext as _ProviderNormalizeModelIdContext,
  ProviderNormalizeResolvedModelContext as _ProviderNormalizeResolvedModelContext,
  ProviderNormalizeToolSchemasContext as _ProviderNormalizeToolSchemasContext,
  ProviderNormalizeTransportContext as _ProviderNormalizeTransportContext,
  ProviderPrepareDynamicModelContext as _ProviderPrepareDynamicModelContext,
  ProviderPrepareExtraParamsContext as _ProviderPrepareExtraParamsContext,
  ProviderPrepareRuntimeAuthContext as _ProviderPrepareRuntimeAuthContext,
  ProviderPreparedRuntimeAuth as _ProviderPreparedRuntimeAuth,
  ProviderReasoningOutputMode as _ProviderReasoningOutputMode,
  ProviderReasoningOutputModeContext as _ProviderReasoningOutputModeContext,
  ProviderReplayPolicy as _ProviderReplayPolicy,
  ProviderReplayPolicyContext as _ProviderReplayPolicyContext,
  ProviderReplaySessionEntry as _ProviderReplaySessionEntry,
  ProviderReplaySessionState as _ProviderReplaySessionState,
  ProviderResolveConfigApiKeyContext as _ProviderResolveConfigApiKeyContext,
  ProviderResolveDynamicModelContext as _ProviderResolveDynamicModelContext,
  ProviderResolveTransportTurnStateContext as _ProviderResolveTransportTurnStateContext,
  ProviderResolveUsageAuthContext as _ProviderResolveUsageAuthContext,
  ProviderResolveWebSocketSessionPolicyContext as _ProviderResolveWebSocketSessionPolicyContext,
  ProviderResolvedUsageAuth as _ProviderResolvedUsageAuth,
  ProviderSanitizeReplayHistoryContext as _ProviderSanitizeReplayHistoryContext,
  ProviderThinkingPolicyContext as _ProviderThinkingPolicyContext,
  ProviderThinkingProfile as _ProviderThinkingProfile,
  ProviderToolSchemaDiagnostic as _ProviderToolSchemaDiagnostic,
  ProviderTransportTurnState as _ProviderTransportTurnState,
  ProviderUsageAuthToken as _ProviderUsageAuthToken,
  ProviderValidateReplayTurnsContext as _ProviderValidateReplayTurnsContext,
  ProviderWebSocketSessionPolicy as _ProviderWebSocketSessionPolicy,
  ProviderWrapStreamFnContext as _ProviderWrapStreamFnContext,
  RealtimeTranscriptionProviderPlugin as _RealtimeTranscriptionProviderPlugin,
  SpeechProviderPlugin as _SpeechProviderPlugin,
  TranscriptSourceProvider as _TranscriptSourceProvider,
  UnifiedModelCatalogProviderContext as _UnifiedModelCatalogProviderContext,
  UnifiedModelCatalogProviderPlugin as _UnifiedModelCatalogProviderPlugin,
  WorkerLease as _WorkerLease,
  WorkerLeaseStatus as _WorkerLeaseStatus,
  WorkerProfile as _WorkerProfile,
  WorkerProvider as _WorkerProvider,
  WorkerSshEndpoint as _WorkerSshEndpoint,
  WorkerSshIdentity as _WorkerSshIdentity,
  WorkerSshIdentityRequest as _WorkerSshIdentityRequest,
} from "../plugins/types.js";
import { createCachedLazyValueGetter } from "./lazy-value.js";

// Local alias declarations keep the .d.ts bundler materializing these names in
// this chunk; direct re-exports break rolldown-plugin-dts chunk generation.
export type AgentHarness = _AgentHarness;
export type AgentPromptGuidance = _AgentPromptGuidance;
export type AgentPromptGuidanceEntry = _AgentPromptGuidanceEntry;
export type AgentPromptSurfaceKind = _AgentPromptSurfaceKind;
export type AnyAgentTool = _AnyAgentTool;
export type MediaUnderstandingProviderPlugin = _MediaUnderstandingProviderPlugin;
export type MigrationApplyResult = _MigrationApplyResult;
export type MigrationDetection = _MigrationDetection;
export type MigrationItem = _MigrationItem;
export type MigrationPlan = _MigrationPlan;
export type MigrationProviderContext = _MigrationProviderContext;
export type MigrationProviderPlugin = _MigrationProviderPlugin;
// The plugin-authoring scaffold generates code importing ProviderPlugin from this entrypoint.
export type ProviderPlugin = _ProviderPlugin;
export type MigrationSummary = _MigrationSummary;
export type NovaGatewayDiscoveryAdvertiseContext = _NovaGatewayDiscoveryAdvertiseContext;
export type NovaGatewayDiscoveryService = _NovaGatewayDiscoveryService;
export type NovaPluginApi = _NovaPluginApi;
export type NovaPluginCommandDefinition = _NovaPluginCommandDefinition;
export type NovaPluginConfigSchema = _NovaPluginConfigSchema;
export type NovaPluginDefinition = _NovaPluginDefinition;
export type NovaPluginHttpRouteHandler = _NovaPluginHttpRouteHandler;
export type NovaPluginNodeHostCommand = _NovaPluginNodeHostCommand;
export type NovaPluginNodeHostCommandAvailabilityContext =
  _NovaPluginNodeHostCommandAvailabilityContext;
export type NovaPluginNodeInvokePolicy = _NovaPluginNodeInvokePolicy;
export type NovaPluginNodeInvokePolicyContext = _NovaPluginNodeInvokePolicyContext;
export type NovaPluginNodeInvokePolicyResult = _NovaPluginNodeInvokePolicyResult;
export type NovaPluginReloadRegistration = _NovaPluginReloadRegistration;
export type NovaPluginSecurityAuditCollector = _NovaPluginSecurityAuditCollector;
export type NovaPluginSecurityAuditContext = _NovaPluginSecurityAuditContext;
export type NovaPluginService = _NovaPluginService;
export type NovaPluginServiceContext = _NovaPluginServiceContext;
export type NovaPluginToolContext = _NovaPluginToolContext;
export type NovaPluginToolFactory = _NovaPluginToolFactory;
export type PluginAgentEventEmitParams = _PluginAgentEventEmitParams;
export type PluginAgentEventEmitResult = _PluginAgentEventEmitResult;
export type PluginAgentEventSubscriptionRegistration = _PluginAgentEventSubscriptionRegistration;
export type PluginAgentTurnPrepareEvent = _PluginAgentTurnPrepareEvent;
export type PluginAgentTurnPrepareResult = _PluginAgentTurnPrepareResult;
export type PluginCommandContext = _PluginCommandContext;
export type PluginCommandResult = _PluginCommandResult;
export type PluginControlUiDescriptor = _PluginControlUiDescriptor;
export type PluginHeartbeatPromptContributionEvent = _PluginHeartbeatPromptContributionEvent;
export type PluginHeartbeatPromptContributionResult = _PluginHeartbeatPromptContributionResult;
export type PluginJsonValue = _PluginJsonValue;
export type PluginLogger = _PluginLogger;
export type PluginNextTurnInjection = _PluginNextTurnInjection;
export type PluginNextTurnInjectionEnqueueResult = _PluginNextTurnInjectionEnqueueResult;
export type PluginNextTurnInjectionRecord = _PluginNextTurnInjectionRecord;
export type PluginRunContextGetParams = _PluginRunContextGetParams;
export type PluginRunContextPatch = _PluginRunContextPatch;
export type PluginRuntimeLifecycleRegistration = _PluginRuntimeLifecycleRegistration;
export type PluginSessionActionContext = _PluginSessionActionContext;
export type PluginSessionActionRegistration = _PluginSessionActionRegistration;
export type PluginSessionActionResult = _PluginSessionActionResult;
export type PluginSessionAttachmentParams = _PluginSessionAttachmentParams;
export type PluginSessionAttachmentResult = _PluginSessionAttachmentResult;
export type PluginSessionExtensionProjection = _PluginSessionExtensionProjection;
export type PluginSessionExtensionRegistration = _PluginSessionExtensionRegistration;
export type PluginSessionSchedulerJobHandle = _PluginSessionSchedulerJobHandle;
export type PluginSessionSchedulerJobRegistration = _PluginSessionSchedulerJobRegistration;
export type PluginSessionTurnScheduleParams = _PluginSessionTurnScheduleParams;
export type PluginSessionTurnUnscheduleByTagParams = _PluginSessionTurnUnscheduleByTagParams;
export type PluginSessionTurnUnscheduleByTagResult = _PluginSessionTurnUnscheduleByTagResult;
export type PluginToolMetadataRegistration = _PluginToolMetadataRegistration;
export type PluginTrustedToolPolicyRegistration = _PluginTrustedToolPolicyRegistration;
export type ProviderApplyConfigDefaultsContext = _ProviderApplyConfigDefaultsContext;
export type ProviderAugmentModelCatalogContext = _ProviderAugmentModelCatalogContext;
export type ProviderAuthContext = _ProviderAuthContext;
export type ProviderAuthDoctorHintContext = _ProviderAuthDoctorHintContext;
export type ProviderAuthMethod = _ProviderAuthMethod;
export type ProviderAuthMethodNonInteractiveContext = _ProviderAuthMethodNonInteractiveContext;
export type ProviderAppGuidedSetup = _ProviderAppGuidedSetup;
export type ProviderAppGuidedSetupCandidate = _ProviderAppGuidedSetupCandidate;
export type ProviderAppGuidedSetupContext = _ProviderAppGuidedSetupContext;
export type ProviderAuthResult = _ProviderAuthResult;
export type ProviderBuildMissingAuthMessageContext = _ProviderBuildMissingAuthMessageContext;
export type ProviderBuildUnknownModelHintContext = _ProviderBuildUnknownModelHintContext;
export type ProviderBuiltInModelSuppressionContext = _ProviderBuiltInModelSuppressionContext;
export type ProviderBuiltInModelSuppressionResult = _ProviderBuiltInModelSuppressionResult;
export type ProviderCacheTtlEligibilityContext = _ProviderCacheTtlEligibilityContext;
export type ProviderCatalogContext = _ProviderCatalogContext;
export type ProviderCatalogResult = _ProviderCatalogResult;
export type ProviderDefaultThinkingPolicyContext = _ProviderDefaultThinkingPolicyContext;
export type ProviderDeferSyntheticProfileAuthContext = _ProviderDeferSyntheticProfileAuthContext;
export type ProviderFailoverErrorContext = _ProviderFailoverErrorContext;
export type ProviderFetchUsageSnapshotContext = _ProviderFetchUsageSnapshotContext;
export type ProviderModernModelPolicyContext = _ProviderModernModelPolicyContext;
export type ProviderNormalizeConfigContext = _ProviderNormalizeConfigContext;
export type ProviderNormalizeModelIdContext = _ProviderNormalizeModelIdContext;
export type ProviderNormalizeResolvedModelContext = _ProviderNormalizeResolvedModelContext;
export type ProviderNormalizeToolSchemasContext = _ProviderNormalizeToolSchemasContext;
export type ProviderNormalizeTransportContext = _ProviderNormalizeTransportContext;
export type ProviderPrepareDynamicModelContext = _ProviderPrepareDynamicModelContext;
export type ProviderPrepareExtraParamsContext = _ProviderPrepareExtraParamsContext;
export type ProviderPrepareRuntimeAuthContext = _ProviderPrepareRuntimeAuthContext;
export type ProviderPreparedRuntimeAuth = _ProviderPreparedRuntimeAuth;
export type ProviderReasoningOutputMode = _ProviderReasoningOutputMode;
export type ProviderReasoningOutputModeContext = _ProviderReasoningOutputModeContext;
export type ProviderReplayPolicy = _ProviderReplayPolicy;
export type ProviderReplayPolicyContext = _ProviderReplayPolicyContext;
export type ProviderReplaySessionEntry = _ProviderReplaySessionEntry;
export type ProviderReplaySessionState = _ProviderReplaySessionState;
export type ProviderResolveConfigApiKeyContext = _ProviderResolveConfigApiKeyContext;
export type ProviderResolveDynamicModelContext = _ProviderResolveDynamicModelContext;
export type ProviderResolveTransportTurnStateContext = _ProviderResolveTransportTurnStateContext;
export type ProviderResolveUsageAuthContext = _ProviderResolveUsageAuthContext;
export type ProviderResolveWebSocketSessionPolicyContext =
  _ProviderResolveWebSocketSessionPolicyContext;
export type ProviderResolvedUsageAuth = _ProviderResolvedUsageAuth;
export type ProviderSanitizeReplayHistoryContext = _ProviderSanitizeReplayHistoryContext;
export type ProviderThinkingPolicyContext = _ProviderThinkingPolicyContext;
export type ProviderThinkingProfile = _ProviderThinkingProfile;
export type ProviderToolSchemaDiagnostic = _ProviderToolSchemaDiagnostic;
export type ProviderTransportTurnState = _ProviderTransportTurnState;
export type ProviderUsageAuthToken = _ProviderUsageAuthToken;
export type ProviderValidateReplayTurnsContext = _ProviderValidateReplayTurnsContext;
export type ProviderWebSocketSessionPolicy = _ProviderWebSocketSessionPolicy;
export type ProviderWrapStreamFnContext = _ProviderWrapStreamFnContext;
export type RealtimeTranscriptionProviderPlugin = _RealtimeTranscriptionProviderPlugin;
export type SpeechProviderPlugin = _SpeechProviderPlugin;
export type TranscriptSourceProvider = _TranscriptSourceProvider;
export type UnifiedModelCatalogProviderContext = _UnifiedModelCatalogProviderContext;
export type UnifiedModelCatalogProviderPlugin = _UnifiedModelCatalogProviderPlugin;
export type WorkerLease = _WorkerLease;
export type WorkerLeaseStatus = _WorkerLeaseStatus;
export type WorkerProfile = _WorkerProfile;
export type WorkerProvider = _WorkerProvider;
export type WorkerSshEndpoint = _WorkerSshEndpoint;
export type WorkerSshIdentity = _WorkerSshIdentity;
export type WorkerSshIdentityRequest = _WorkerSshIdentityRequest;

export type NovaPluginGatewayEventScope =
  import("../plugins/gateway-events.js").NovaPluginGatewayEventScope;
export type NovaPluginGatewayEvents =
  import("../plugins/gateway-events.js").NovaPluginGatewayEvents;
export { WorkerProviderError } from "../plugins/types.js";

export type {
  PluginConversationBinding,
  PluginConversationBindingResolvedEvent,
  PluginConversationBindingRequestParams,
  PluginConversationBindingRequestResult,
} from "../plugins/conversation-binding.types.js";
export type {
  PluginHookInboundClaimContext,
  PluginHookInboundClaimEvent,
  PluginHookInboundClaimResult,
} from "../plugins/hook-types.js";
export type { ProviderRuntimeModel } from "../plugins/provider-runtime-model.types.js";
export type {
  UnifiedModelCatalogEntry,
  UnifiedModelCatalogKind,
  UnifiedModelCatalogSource,
} from "@nova/model-catalog-core/model-catalog-types";
export type { NovaConfig };

export {
  buildJsonPluginConfigSchema,
  buildPluginConfigSchema,
  emptyPluginConfigSchema,
} from "../plugins/config-schema.js";

/** Options for a plugin entry that registers providers, tools, commands, or services. */
type DefinePluginEntryOptions = {
  id: string;
  name: string;
  description: string;
  /**
   * @deprecated Declare exclusive plugin kind in `nova.plugin.json` via
   * manifest `kind`. Runtime-entry `kind` remains only as a compatibility
   * fallback for older plugins.
   */
  kind?: NovaPluginDefinition["kind"];
  configSchema?: NovaPluginConfigSchema | (() => NovaPluginConfigSchema);
  reload?: NovaPluginDefinition["reload"];
  nodeHostCommands?: NovaPluginDefinition["nodeHostCommands"];
  securityAuditCollectors?: NovaPluginDefinition["securityAuditCollectors"];
  register: (api: NovaPluginApi) => void;
};

/** Normalized object shape that Nova loads from a plugin entry module. */
type DefinedPluginEntry = {
  id: string;
  name: string;
  description: string;
  configSchema: NovaPluginConfigSchema;
  register: NonNullable<NovaPluginDefinition["register"]>;
} & Pick<NovaPluginDefinition, "kind" | "reload" | "nodeHostCommands" | "securityAuditCollectors">;

/**
 * Canonical entry helper for non-channel plugins.
 *
 * Use this for provider, tool, command, service, memory, and context-engine
 * plugins. Channel plugins should use `defineChannelPluginEntry(...)` from
 * `nova/plugin-sdk/core` so they inherit the channel capability wiring.
 */
export function definePluginEntry({
  id,
  name,
  description,
  kind,
  configSchema = emptyPluginConfigSchema,
  reload,
  nodeHostCommands,
  securityAuditCollectors,
  register,
}: DefinePluginEntryOptions): DefinedPluginEntry {
  const getConfigSchema = createCachedLazyValueGetter(configSchema);
  return {
    id,
    name,
    description,
    ...(kind ? { kind } : {}),
    ...(reload ? { reload } : {}),
    ...(nodeHostCommands ? { nodeHostCommands } : {}),
    ...(securityAuditCollectors ? { securityAuditCollectors } : {}),
    get configSchema() {
      return getConfigSchema();
    },
    register,
  };
}
