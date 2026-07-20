package ai.nova.app.protocol

import org.junit.Assert.assertTrue
import org.junit.Test

class NovaProtocolConstantsTest {
  @Test
  fun generatedCapabilitiesAreUniqueProtocolIds() {
    val values = NovaCapability.entries.map { it.rawValue }

    assertTrue(values.isNotEmpty())
    assertTrue(values.all { it.isNotBlank() && "." !in it })
    assertTrue(values.size == values.toSet().size)
  }

  @Test
  fun generatedCommandGroupsMatchTheirNamespaces() {
    val groups =
      listOf(
        NovaCanvasCommand.NamespacePrefix to NovaCanvasCommand.entries.map { it.rawValue },
        NovaCanvasA2UICommand.NamespacePrefix to NovaCanvasA2UICommand.entries.map { it.rawValue },
        NovaCameraCommand.NamespacePrefix to NovaCameraCommand.entries.map { it.rawValue },
        NovaSmsCommand.NamespacePrefix to NovaSmsCommand.entries.map { it.rawValue },
        NovaTalkCommand.NamespacePrefix to NovaTalkCommand.entries.map { it.rawValue },
        NovaLocationCommand.NamespacePrefix to NovaLocationCommand.entries.map { it.rawValue },
        NovaDeviceCommand.NamespacePrefix to NovaDeviceCommand.entries.map { it.rawValue },
        NovaNotificationsCommand.NamespacePrefix to NovaNotificationsCommand.entries.map { it.rawValue },
        NovaSystemCommand.NamespacePrefix to NovaSystemCommand.entries.map { it.rawValue },
        NovaPhotosCommand.NamespacePrefix to NovaPhotosCommand.entries.map { it.rawValue },
        NovaContactsCommand.NamespacePrefix to NovaContactsCommand.entries.map { it.rawValue },
        NovaCalendarCommand.NamespacePrefix to NovaCalendarCommand.entries.map { it.rawValue },
        NovaMotionCommand.NamespacePrefix to NovaMotionCommand.entries.map { it.rawValue },
        NovaCallLogCommand.NamespacePrefix to NovaCallLogCommand.entries.map { it.rawValue },
      )

    val commands = groups.flatMap { (prefix, values) -> values.onEach { assertTrue(it.startsWith(prefix)) } }
    assertTrue(commands.size == commands.toSet().size)
  }
}
