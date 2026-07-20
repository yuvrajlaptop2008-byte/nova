package ai.nova.app.node

import ai.nova.app.protocol.NovaCalendarCommand
import ai.nova.app.protocol.NovaCallLogCommand
import ai.nova.app.protocol.NovaCameraCommand
import ai.nova.app.protocol.NovaCapability
import ai.nova.app.protocol.NovaContactsCommand
import ai.nova.app.protocol.NovaDeviceCommand
import ai.nova.app.protocol.NovaLocationCommand
import ai.nova.app.protocol.NovaMotionCommand
import ai.nova.app.protocol.NovaNotificationsCommand
import ai.nova.app.protocol.NovaPhotosCommand
import ai.nova.app.protocol.NovaSmsCommand
import ai.nova.app.protocol.NovaSystemCommand
import ai.nova.app.protocol.NovaTalkCommand
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class InvokeCommandRegistryTest {
  private val coreCapabilities =
    setOf(
      NovaCapability.Canvas.rawValue,
      NovaCapability.Device.rawValue,
      NovaCapability.Notifications.rawValue,
      NovaCapability.System.rawValue,
      NovaCapability.Talk.rawValue,
      NovaCapability.Contacts.rawValue,
      NovaCapability.Calendar.rawValue,
    )

  private val optionalCapabilities =
    setOf(
      NovaCapability.Camera.rawValue,
      NovaCapability.Location.rawValue,
      NovaCapability.Sms.rawValue,
      NovaCapability.CallLog.rawValue,
      NovaCapability.Motion.rawValue,
      NovaCapability.Photos.rawValue,
      NovaCapability.VoiceWake.rawValue,
    )

  private val coreCommands =
    setOf(
      NovaDeviceCommand.Status.rawValue,
      NovaDeviceCommand.Info.rawValue,
      NovaDeviceCommand.Permissions.rawValue,
      NovaDeviceCommand.Health.rawValue,
      NovaNotificationsCommand.List.rawValue,
      NovaNotificationsCommand.Actions.rawValue,
      NovaSystemCommand.Notify.rawValue,
      NovaTalkCommand.PttStart.rawValue,
      NovaTalkCommand.PttStop.rawValue,
      NovaTalkCommand.PttCancel.rawValue,
      NovaTalkCommand.PttOnce.rawValue,
      NovaContactsCommand.Search.rawValue,
      NovaContactsCommand.Add.rawValue,
      NovaCalendarCommand.Events.rawValue,
      NovaCalendarCommand.Add.rawValue,
    )

  private val optionalCommands =
    setOf(
      NovaCameraCommand.Snap.rawValue,
      NovaCameraCommand.Clip.rawValue,
      NovaCameraCommand.List.rawValue,
      NovaLocationCommand.Get.rawValue,
      NovaMotionCommand.Activity.rawValue,
      NovaMotionCommand.Pedometer.rawValue,
      NovaSmsCommand.Send.rawValue,
      NovaSmsCommand.Search.rawValue,
      NovaCallLogCommand.Search.rawValue,
      NovaPhotosCommand.Latest.rawValue,
    )

  private val debugCommands = setOf("debug.logs", "debug.ed25519")

  @Test
  fun advertisedCapabilities_respectsFeatureAvailability() {
    val capabilities = InvokeCommandRegistry.advertisedCapabilities(defaultFlags())

    assertContainsAll(capabilities, coreCapabilities)
    assertMissingAll(capabilities, optionalCapabilities)
  }

  @Test
  fun advertisedCapabilities_includesFeatureCapabilitiesWhenEnabled() {
    val capabilities =
      InvokeCommandRegistry.advertisedCapabilities(
        defaultFlags(
          cameraEnabled = true,
          locationEnabled = true,
          sendSmsAvailable = true,
          readSmsAvailable = true,
          smsSearchPossible = true,
          callLogAvailable = true,
          photosAvailable = true,
          motionActivityAvailable = true,
          motionPedometerAvailable = true,
          voiceWakeEnabled = true,
        ),
      )

    assertContainsAll(capabilities, coreCapabilities + optionalCapabilities)
  }

  @Test
  fun advertisedCommands_respectsFeatureAvailability() {
    val commands = InvokeCommandRegistry.advertisedCommands(defaultFlags())

    assertContainsAll(commands, coreCommands)
    assertMissingAll(commands, optionalCommands + debugCommands)
  }

  @Test
  fun advertisedCommands_includesDeviceAppsOnlyWhenUserOptedIn() {
    val disabled = InvokeCommandRegistry.advertisedCommands(defaultFlags(installedAppsSharingEnabled = false))
    val enabled = InvokeCommandRegistry.advertisedCommands(defaultFlags(installedAppsSharingEnabled = true))

    assertFalse(disabled.contains(NovaDeviceCommand.Apps.rawValue))
    assertTrue(enabled.contains(NovaDeviceCommand.Apps.rawValue))
  }

  @Test
  fun advertisedCommands_includesFeatureCommandsWhenEnabled() {
    val commands =
      InvokeCommandRegistry.advertisedCommands(
        defaultFlags(
          cameraEnabled = true,
          locationEnabled = true,
          sendSmsAvailable = true,
          readSmsAvailable = true,
          smsSearchPossible = true,
          callLogAvailable = true,
          photosAvailable = true,
          motionActivityAvailable = true,
          motionPedometerAvailable = true,
          debugBuild = true,
        ),
      )

    assertContainsAll(commands, coreCommands + optionalCommands + debugCommands)
  }

  @Test
  fun advertisedCommands_onlyIncludesSupportedMotionCommands() {
    val commands =
      InvokeCommandRegistry.advertisedCommands(
        NodeRuntimeFlags(
          cameraEnabled = false,
          locationEnabled = false,
          sendSmsAvailable = false,
          readSmsAvailable = false,
          smsSearchPossible = false,
          callLogAvailable = false,
          photosAvailable = false,
          motionActivityAvailable = true,
          motionPedometerAvailable = false,
          installedAppsSharingEnabled = false,
          debugBuild = false,
        ),
      )

    assertTrue(commands.contains(NovaMotionCommand.Activity.rawValue))
    assertFalse(commands.contains(NovaMotionCommand.Pedometer.rawValue))
  }

  @Test
  fun advertisedCommands_splitsSmsSendAndSearchAvailability() {
    val readOnlyCommands =
      InvokeCommandRegistry.advertisedCommands(
        defaultFlags(readSmsAvailable = true, smsSearchPossible = true),
      )
    val sendOnlyCommands =
      InvokeCommandRegistry.advertisedCommands(
        defaultFlags(sendSmsAvailable = true),
      )
    val requestableSearchCommands =
      InvokeCommandRegistry.advertisedCommands(
        defaultFlags(smsSearchPossible = true),
      )

    assertTrue(readOnlyCommands.contains(NovaSmsCommand.Search.rawValue))
    assertFalse(readOnlyCommands.contains(NovaSmsCommand.Send.rawValue))
    assertTrue(sendOnlyCommands.contains(NovaSmsCommand.Send.rawValue))
    assertFalse(sendOnlyCommands.contains(NovaSmsCommand.Search.rawValue))
    assertTrue(requestableSearchCommands.contains(NovaSmsCommand.Search.rawValue))
  }

  @Test
  fun advertisedCapabilities_includeSmsWhenEitherSmsPathIsAvailable() {
    val readOnlyCapabilities =
      InvokeCommandRegistry.advertisedCapabilities(
        defaultFlags(readSmsAvailable = true),
      )
    val sendOnlyCapabilities =
      InvokeCommandRegistry.advertisedCapabilities(
        defaultFlags(sendSmsAvailable = true),
      )
    val requestableSearchCapabilities =
      InvokeCommandRegistry.advertisedCapabilities(
        defaultFlags(smsSearchPossible = true),
      )

    assertTrue(readOnlyCapabilities.contains(NovaCapability.Sms.rawValue))
    assertTrue(sendOnlyCapabilities.contains(NovaCapability.Sms.rawValue))
    assertFalse(requestableSearchCapabilities.contains(NovaCapability.Sms.rawValue))
  }

  @Test
  fun advertisedCommands_excludesCallLogWhenUnavailable() {
    val commands = InvokeCommandRegistry.advertisedCommands(defaultFlags(callLogAvailable = false))

    assertFalse(commands.contains(NovaCallLogCommand.Search.rawValue))
  }

  @Test
  fun advertisedCapabilities_excludesCallLogWhenUnavailable() {
    val capabilities = InvokeCommandRegistry.advertisedCapabilities(defaultFlags(callLogAvailable = false))

    assertFalse(capabilities.contains(NovaCapability.CallLog.rawValue))
  }

  @Test
  fun advertisedPhotosSurface_respectsFeatureAvailability() {
    val disabledFlags = defaultFlags(photosAvailable = false)
    val enabledFlags = defaultFlags(photosAvailable = true)

    assertFalse(InvokeCommandRegistry.advertisedCapabilities(disabledFlags).contains(NovaCapability.Photos.rawValue))
    assertFalse(InvokeCommandRegistry.advertisedCommands(disabledFlags).contains(NovaPhotosCommand.Latest.rawValue))
    assertTrue(InvokeCommandRegistry.advertisedCapabilities(enabledFlags).contains(NovaCapability.Photos.rawValue))
    assertTrue(InvokeCommandRegistry.advertisedCommands(enabledFlags).contains(NovaPhotosCommand.Latest.rawValue))
  }

  @Test
  fun find_returnsForegroundMetadataForCameraCommands() {
    val list = InvokeCommandRegistry.find(NovaCameraCommand.List.rawValue)
    val location = InvokeCommandRegistry.find(NovaLocationCommand.Get.rawValue)
    val pttStart = InvokeCommandRegistry.find(NovaTalkCommand.PttStart.rawValue)
    val pttStop = InvokeCommandRegistry.find(NovaTalkCommand.PttStop.rawValue)
    val pttCancel = InvokeCommandRegistry.find(NovaTalkCommand.PttCancel.rawValue)
    val pttOnce = InvokeCommandRegistry.find(NovaTalkCommand.PttOnce.rawValue)

    assertNotNull(list)
    assertEquals(true, list?.requiresForeground)
    assertNotNull(location)
    assertEquals(false, location?.requiresForeground)
    assertNotNull(pttStart)
    assertEquals(false, pttStart?.requiresForeground)
    assertNotNull(pttStop)
    assertEquals(false, pttStop?.requiresForeground)
    assertNotNull(pttCancel)
    assertEquals(false, pttCancel?.requiresForeground)
    assertNotNull(pttOnce)
    assertEquals(true, pttOnce?.requiresForeground)
  }

  @Test
  fun find_returnsNullForUnknownCommand() {
    assertNull(InvokeCommandRegistry.find("not.real"))
  }

  private fun defaultFlags(
    cameraEnabled: Boolean = false,
    locationEnabled: Boolean = false,
    sendSmsAvailable: Boolean = false,
    readSmsAvailable: Boolean = false,
    smsSearchPossible: Boolean = false,
    callLogAvailable: Boolean = false,
    photosAvailable: Boolean = false,
    motionActivityAvailable: Boolean = false,
    motionPedometerAvailable: Boolean = false,
    installedAppsSharingEnabled: Boolean = false,
    debugBuild: Boolean = false,
    voiceWakeEnabled: Boolean = false,
  ): NodeRuntimeFlags =
    NodeRuntimeFlags(
      cameraEnabled = cameraEnabled,
      locationEnabled = locationEnabled,
      sendSmsAvailable = sendSmsAvailable,
      readSmsAvailable = readSmsAvailable,
      smsSearchPossible = smsSearchPossible,
      callLogAvailable = callLogAvailable,
      photosAvailable = photosAvailable,
      motionActivityAvailable = motionActivityAvailable,
      motionPedometerAvailable = motionPedometerAvailable,
      installedAppsSharingEnabled = installedAppsSharingEnabled,
      debugBuild = debugBuild,
      voiceWakeEnabled = voiceWakeEnabled,
    )

  private fun assertContainsAll(
    actual: List<String>,
    expected: Set<String>,
  ) {
    expected.forEach { value -> assertTrue(actual.contains(value)) }
  }

  private fun assertMissingAll(
    actual: List<String>,
    forbidden: Set<String>,
  ) {
    forbidden.forEach { value -> assertFalse(actual.contains(value)) }
  }
}
