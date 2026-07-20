// Builds plugin API objects from config, registries, and runtime helpers.
import type { NovaConfig } from "../config/types.nova.js";
import { attachPluginApiFacades, type NovaPluginApiWithoutFacades } from "./api-facades.js";
import type { PluginRuntime } from "./runtime/types.js";
import type { NovaPluginApi, PluginLogger } from "./types.js";

type BuildPluginApiParams = {
  id: string;
  name: string;
  version?: string;
  description?: string;
  source: string;
  rootDir?: string;
  registrationMode: NovaPluginApi["registrationMode"];
  config: NovaConfig;
  pluginConfig?: Record<string, unknown>;
  runtime: PluginRuntime;
  logger: PluginLogger;
  resolvePath: (input: string) => string;
  handlers?: Partial<
    Pick<
      NovaPluginApi,
      | "registerTool"
      | "registerHook"
      | "registerHttpRoute"
      | "registerHostedMediaResolver"
      | "registerMcpServerConnectionResolver"
      | "registerChannel"
      | "registerGatewayMethod"
      | "registerSessionCatalog"
      | "registerCli"
      | "registerReload"
      | "registerNodeHostCommand"
      | "registerNodeInvokePolicy"
      | "registerSecurityAuditCollector"
      | "registerService"
      | "registerGatewayDiscoveryService"
      | "registerCliBackend"
      | "registerTextTransforms"
      | "registerConfigMigration"
      | "registerMigrationProvider"
      | "registerAutoEnableProbe"
      | "registerProvider"
      | "registerWorkerProvider"
      | "registerModelCatalogProvider"
      | "registerEmbeddingProvider"
      | "registerSpeechProvider"
      | "registerRealtimeTranscriptionProvider"
      | "registerRealtimeVoiceProvider"
      | "registerMediaUnderstandingProvider"
      | "registerTranscriptSourceProvider"
      | "registerImageGenerationProvider"
      | "registerVideoGenerationProvider"
      | "registerMusicGenerationProvider"
      | "registerWebFetchProvider"
      | "registerWebSearchProvider"
      | "registerInteractiveHandler"
      | "onConversationBindingResolved"
      | "registerCommand"
      | "registerContextEngine"
      | "registerCompactionProvider"
      | "registerAgentHarness"
      | "registerCodexAppServerExtensionFactory"
      | "registerAgentToolResultMiddleware"
      | "registerSessionExtension"
      | "enqueueNextTurnInjection"
      | "registerTrustedToolPolicy"
      | "registerToolMetadata"
      | "registerControlUiDescriptor"
      | "registerRuntimeLifecycle"
      | "registerAgentEventSubscription"
      | "emitAgentEvent"
      | "setRunContext"
      | "getRunContext"
      | "clearRunContext"
      | "registerSessionSchedulerJob"
      | "registerSessionAction"
      | "sendSessionAttachment"
      | "scheduleSessionTurn"
      | "unscheduleSessionTurnsByTag"
      | "registerDetachedTaskRuntime"
      | "registerMemoryCapability"
      | "registerMemoryPromptSupplement"
      | "registerMemoryPromptPreparation"
      | "registerMemoryCorpusSupplement"
      | "registerMemoryEmbeddingProvider"
      | "on"
    >
  >;
};

const noopRegisterTool: NovaPluginApi["registerTool"] = () => {};
const noopRegisterHook: NovaPluginApi["registerHook"] = () => {};
const noopRegisterHttpRoute: NovaPluginApi["registerHttpRoute"] = () => {};
const noopRegisterHostedMediaResolver: NovaPluginApi["registerHostedMediaResolver"] = () => {};
const noopRegisterMcpServerConnectionResolver: NovaPluginApi["registerMcpServerConnectionResolver"] =
  () => {};
const noopRegisterChannel: NovaPluginApi["registerChannel"] = () => {};
const noopRegisterGatewayMethod: NovaPluginApi["registerGatewayMethod"] = () => {};
const noopRegisterSessionCatalog: NovaPluginApi["registerSessionCatalog"] = () => {};
const noopRegisterCli: NovaPluginApi["registerCli"] = () => {};
const noopRegisterReload: NovaPluginApi["registerReload"] = () => {};
const noopRegisterNodeHostCommand: NovaPluginApi["registerNodeHostCommand"] = () => {};
const noopRegisterNodeInvokePolicy: NovaPluginApi["registerNodeInvokePolicy"] = () => {};
const noopRegisterSecurityAuditCollector: NovaPluginApi["registerSecurityAuditCollector"] =
  () => {};
const noopRegisterService: NovaPluginApi["registerService"] = () => {};
const noopRegisterGatewayDiscoveryService: NovaPluginApi["registerGatewayDiscoveryService"] =
  () => {};
const noopRegisterCliBackend: NovaPluginApi["registerCliBackend"] = () => {};
const noopRegisterTextTransforms: NovaPluginApi["registerTextTransforms"] = () => {};
const noopRegisterConfigMigration: NovaPluginApi["registerConfigMigration"] = () => {};
const noopRegisterMigrationProvider: NovaPluginApi["registerMigrationProvider"] = () => {};
const noopRegisterAutoEnableProbe: NovaPluginApi["registerAutoEnableProbe"] = () => {};
const noopRegisterProvider: NovaPluginApi["registerProvider"] = () => {};
const noopRegisterWorkerProvider: NovaPluginApi["registerWorkerProvider"] = () => {};
const noopRegisterModelCatalogProvider: NovaPluginApi["registerModelCatalogProvider"] = () => {};
const noopRegisterEmbeddingProvider: NovaPluginApi["registerEmbeddingProvider"] = () => {};
const noopRegisterSpeechProvider: NovaPluginApi["registerSpeechProvider"] = () => {};
const noopRegisterRealtimeTranscriptionProvider: NovaPluginApi["registerRealtimeTranscriptionProvider"] =
  () => {};
const noopRegisterRealtimeVoiceProvider: NovaPluginApi["registerRealtimeVoiceProvider"] = () => {};
const noopRegisterMediaUnderstandingProvider: NovaPluginApi["registerMediaUnderstandingProvider"] =
  () => {};
const noopRegisterTranscriptsSourceProvider: NovaPluginApi["registerTranscriptSourceProvider"] =
  () => {};
const noopRegisterImageGenerationProvider: NovaPluginApi["registerImageGenerationProvider"] =
  () => {};
const noopRegisterVideoGenerationProvider: NovaPluginApi["registerVideoGenerationProvider"] =
  () => {};
const noopRegisterMusicGenerationProvider: NovaPluginApi["registerMusicGenerationProvider"] =
  () => {};
const noopRegisterWebFetchProvider: NovaPluginApi["registerWebFetchProvider"] = () => {};
const noopRegisterWebSearchProvider: NovaPluginApi["registerWebSearchProvider"] = () => {};
const noopRegisterInteractiveHandler: NovaPluginApi["registerInteractiveHandler"] = () => {};
const noopOnConversationBindingResolved: NovaPluginApi["onConversationBindingResolved"] = () => {};
const noopRegisterCommand: NovaPluginApi["registerCommand"] = () => {};
const noopRegisterContextEngine: NovaPluginApi["registerContextEngine"] = () => {};
const noopRegisterCompactionProvider: NovaPluginApi["registerCompactionProvider"] = () => {};
const noopRegisterAgentHarness: NovaPluginApi["registerAgentHarness"] = () => {};
const noopRegisterCodexAppServerExtensionFactory: NovaPluginApi["registerCodexAppServerExtensionFactory"] =
  () => {};
const noopRegisterAgentToolResultMiddleware: NovaPluginApi["registerAgentToolResultMiddleware"] =
  () => {};
const noopRegisterSessionExtension: NovaPluginApi["registerSessionExtension"] = () => {};
const noopEnqueueNextTurnInjection: NovaPluginApi["enqueueNextTurnInjection"] = async (
  injection,
) => ({ enqueued: false, id: "", sessionKey: injection.sessionKey });
const noopRegisterTrustedToolPolicy: NovaPluginApi["registerTrustedToolPolicy"] = () => {};
const noopRegisterToolMetadata: NovaPluginApi["registerToolMetadata"] = () => {};
const noopRegisterControlUiDescriptor: NovaPluginApi["registerControlUiDescriptor"] = () => {};
const noopRegisterRuntimeLifecycle: NovaPluginApi["registerRuntimeLifecycle"] = () => {};
const noopRegisterAgentEventSubscription: NovaPluginApi["registerAgentEventSubscription"] =
  () => {};
const noopEmitAgentEvent: NovaPluginApi["emitAgentEvent"] = () => ({
  emitted: false,
  reason: "not wired",
});
const noopSetRunContext: NovaPluginApi["setRunContext"] = () => false;
const noopGetRunContext: NovaPluginApi["getRunContext"] = () => undefined;
const noopClearRunContext: NovaPluginApi["clearRunContext"] = () => {};
const noopRegisterSessionSchedulerJob: NovaPluginApi["registerSessionSchedulerJob"] = () =>
  undefined;
const noopRegisterSessionAction: NovaPluginApi["registerSessionAction"] = () => {};
const noopSendSessionAttachment: NovaPluginApi["sendSessionAttachment"] = async () => ({
  ok: false,
  error: "not wired",
});
const noopScheduleSessionTurn: NovaPluginApi["scheduleSessionTurn"] = async () => undefined;
const noopUnscheduleSessionTurnsByTag: NovaPluginApi["unscheduleSessionTurnsByTag"] = async () => ({
  removed: 0,
  failed: 0,
});
const noopRegisterDetachedTaskRuntime: NovaPluginApi["registerDetachedTaskRuntime"] = () => {};
const noopRegisterMemoryCapability: NovaPluginApi["registerMemoryCapability"] = () => {};
const noopRegisterMemoryPromptSupplement: NovaPluginApi["registerMemoryPromptSupplement"] =
  () => {};
const noopRegisterMemoryPromptPreparation: NovaPluginApi["registerMemoryPromptPreparation"] =
  () => {};
const noopRegisterMemoryCorpusSupplement: NovaPluginApi["registerMemoryCorpusSupplement"] =
  () => {};
const noopRegisterMemoryEmbeddingProvider: NovaPluginApi["registerMemoryEmbeddingProvider"] =
  () => {};
const noopOn: NovaPluginApi["on"] = () => {};

export function buildPluginApi(params: BuildPluginApiParams): NovaPluginApi {
  const handlers = params.handlers ?? {};
  const registerCli = handlers.registerCli ?? noopRegisterCli;
  const api: NovaPluginApiWithoutFacades = {
    id: params.id,
    name: params.name,
    version: params.version,
    description: params.description,
    source: params.source,
    rootDir: params.rootDir,
    registrationMode: params.registrationMode,
    config: params.config,
    pluginConfig: params.pluginConfig,
    runtime: params.runtime,
    logger: params.logger,
    registerTool: handlers.registerTool ?? noopRegisterTool,
    registerHook: handlers.registerHook ?? noopRegisterHook,
    registerHttpRoute: handlers.registerHttpRoute ?? noopRegisterHttpRoute,
    registerHostedMediaResolver:
      handlers.registerHostedMediaResolver ?? noopRegisterHostedMediaResolver,
    registerMcpServerConnectionResolver:
      handlers.registerMcpServerConnectionResolver ?? noopRegisterMcpServerConnectionResolver,
    registerChannel: handlers.registerChannel ?? noopRegisterChannel,
    registerGatewayMethod: handlers.registerGatewayMethod ?? noopRegisterGatewayMethod,
    registerSessionCatalog: handlers.registerSessionCatalog ?? noopRegisterSessionCatalog,
    registerCli,
    registerNodeCliFeature: (registrar, opts) =>
      registerCli(registrar, {
        ...opts,
        parentPath: ["nodes"],
      }),
    registerReload: handlers.registerReload ?? noopRegisterReload,
    registerNodeHostCommand: handlers.registerNodeHostCommand ?? noopRegisterNodeHostCommand,
    registerNodeInvokePolicy: handlers.registerNodeInvokePolicy ?? noopRegisterNodeInvokePolicy,
    registerSecurityAuditCollector:
      handlers.registerSecurityAuditCollector ?? noopRegisterSecurityAuditCollector,
    registerService: handlers.registerService ?? noopRegisterService,
    registerGatewayDiscoveryService:
      handlers.registerGatewayDiscoveryService ?? noopRegisterGatewayDiscoveryService,
    registerCliBackend: handlers.registerCliBackend ?? noopRegisterCliBackend,
    registerTextTransforms: handlers.registerTextTransforms ?? noopRegisterTextTransforms,
    registerConfigMigration: handlers.registerConfigMigration ?? noopRegisterConfigMigration,
    registerMigrationProvider: handlers.registerMigrationProvider ?? noopRegisterMigrationProvider,
    registerAutoEnableProbe: handlers.registerAutoEnableProbe ?? noopRegisterAutoEnableProbe,
    registerProvider: handlers.registerProvider ?? noopRegisterProvider,
    registerWorkerProvider: handlers.registerWorkerProvider ?? noopRegisterWorkerProvider,
    registerModelCatalogProvider:
      handlers.registerModelCatalogProvider ?? noopRegisterModelCatalogProvider,
    registerEmbeddingProvider: handlers.registerEmbeddingProvider ?? noopRegisterEmbeddingProvider,
    registerSpeechProvider: handlers.registerSpeechProvider ?? noopRegisterSpeechProvider,
    registerRealtimeTranscriptionProvider:
      handlers.registerRealtimeTranscriptionProvider ?? noopRegisterRealtimeTranscriptionProvider,
    registerRealtimeVoiceProvider:
      handlers.registerRealtimeVoiceProvider ?? noopRegisterRealtimeVoiceProvider,
    registerMediaUnderstandingProvider:
      handlers.registerMediaUnderstandingProvider ?? noopRegisterMediaUnderstandingProvider,
    registerTranscriptSourceProvider:
      handlers.registerTranscriptSourceProvider ?? noopRegisterTranscriptsSourceProvider,
    registerImageGenerationProvider:
      handlers.registerImageGenerationProvider ?? noopRegisterImageGenerationProvider,
    registerVideoGenerationProvider:
      handlers.registerVideoGenerationProvider ?? noopRegisterVideoGenerationProvider,
    registerMusicGenerationProvider:
      handlers.registerMusicGenerationProvider ?? noopRegisterMusicGenerationProvider,
    registerWebFetchProvider: handlers.registerWebFetchProvider ?? noopRegisterWebFetchProvider,
    registerWebSearchProvider: handlers.registerWebSearchProvider ?? noopRegisterWebSearchProvider,
    registerInteractiveHandler:
      handlers.registerInteractiveHandler ?? noopRegisterInteractiveHandler,
    onConversationBindingResolved:
      handlers.onConversationBindingResolved ?? noopOnConversationBindingResolved,
    registerCommand: handlers.registerCommand ?? noopRegisterCommand,
    registerContextEngine: handlers.registerContextEngine ?? noopRegisterContextEngine,
    registerCompactionProvider:
      handlers.registerCompactionProvider ?? noopRegisterCompactionProvider,
    registerAgentHarness: handlers.registerAgentHarness ?? noopRegisterAgentHarness,
    registerCodexAppServerExtensionFactory:
      handlers.registerCodexAppServerExtensionFactory ?? noopRegisterCodexAppServerExtensionFactory,
    registerAgentToolResultMiddleware:
      handlers.registerAgentToolResultMiddleware ?? noopRegisterAgentToolResultMiddleware,
    registerSessionExtension: handlers.registerSessionExtension ?? noopRegisterSessionExtension,
    enqueueNextTurnInjection: handlers.enqueueNextTurnInjection ?? noopEnqueueNextTurnInjection,
    registerTrustedToolPolicy: handlers.registerTrustedToolPolicy ?? noopRegisterTrustedToolPolicy,
    registerToolMetadata: handlers.registerToolMetadata ?? noopRegisterToolMetadata,
    registerControlUiDescriptor:
      handlers.registerControlUiDescriptor ?? noopRegisterControlUiDescriptor,
    registerRuntimeLifecycle: handlers.registerRuntimeLifecycle ?? noopRegisterRuntimeLifecycle,
    registerAgentEventSubscription:
      handlers.registerAgentEventSubscription ?? noopRegisterAgentEventSubscription,
    emitAgentEvent: handlers.emitAgentEvent ?? noopEmitAgentEvent,
    setRunContext: handlers.setRunContext ?? noopSetRunContext,
    getRunContext: handlers.getRunContext ?? noopGetRunContext,
    clearRunContext: handlers.clearRunContext ?? noopClearRunContext,
    registerSessionSchedulerJob:
      handlers.registerSessionSchedulerJob ?? noopRegisterSessionSchedulerJob,
    registerSessionAction: handlers.registerSessionAction ?? noopRegisterSessionAction,
    sendSessionAttachment: handlers.sendSessionAttachment ?? noopSendSessionAttachment,
    scheduleSessionTurn: handlers.scheduleSessionTurn ?? noopScheduleSessionTurn,
    unscheduleSessionTurnsByTag:
      handlers.unscheduleSessionTurnsByTag ?? noopUnscheduleSessionTurnsByTag,
    registerDetachedTaskRuntime:
      handlers.registerDetachedTaskRuntime ?? noopRegisterDetachedTaskRuntime,
    registerMemoryCapability: handlers.registerMemoryCapability ?? noopRegisterMemoryCapability,
    registerMemoryPromptSupplement:
      handlers.registerMemoryPromptSupplement ?? noopRegisterMemoryPromptSupplement,
    registerMemoryPromptPreparation:
      handlers.registerMemoryPromptPreparation ?? noopRegisterMemoryPromptPreparation,
    registerMemoryCorpusSupplement:
      handlers.registerMemoryCorpusSupplement ?? noopRegisterMemoryCorpusSupplement,
    registerMemoryEmbeddingProvider:
      handlers.registerMemoryEmbeddingProvider ?? noopRegisterMemoryEmbeddingProvider,
    resolvePath: params.resolvePath,
    on: handlers.on ?? noopOn,
  };
  return attachPluginApiFacades(api);
}
