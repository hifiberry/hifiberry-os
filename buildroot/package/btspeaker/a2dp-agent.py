#!/usr/bin/python

from __future__ import absolute_import, print_function, unicode_literals

import sys
import dbus
import dbus.service
import dbus.mainloop.glib
try:
    from gi.repository import GObject
except ImportError:
    import gobject as GObject

AGENT_INTERFACE = "org.bluez.Agent1"
AGENT_PATH = "/test/agent"


class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


class Agent(dbus.service.Object):
    exit_on_release = True

    def set_exit_on_release(self, exit_on_release):
        self.exit_on_release = exit_on_release

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="", out_signature="")
    def Release(self):
        print("Release")
        if self.exit_on_release:
            mainloop.quit()

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        print("AuthorizeService (%s, %s)" % (device, uuid))
        if uuid == "0000110d-0000-1000-8000-00805f9b34fb":
            print("Authorized A2DP Service")
            return
        print("Rejecting non-A2DP Service")
        raise Rejected("Connection rejected")

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        print("RequestPinCode (%s)" % (device))
        return "0000"

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        print("RequestPasskey (%s)" % (device))
        return dbus.UInt32("password")

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        print("DisplayPasskey (%s, %06u entered %u)" %
              (device, passkey, entered))

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        print("DisplayPinCode (%s, %s)" % (device, pincode))

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        print("RequestConfirmation (%s, %06d)" % (device, passkey))
        return

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        print("RequestAuthorization (%s)" % (device))
        raise Rejected("Pairing rejected")

    @dbus.service.method(AGENT_INTERFACE,
                         in_signature="", out_signature="")
    def Cancel(self):
        print("Cancel")


if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()

    agent = Agent(bus, AGENT_PATH)

    obj = bus.get_object("org.bluez", "/org/bluez")
    manager = dbus.Interface(obj, "org.bluez.AgentManager1")
    manager.RegisterAgent(AGENT_PATH, "NoInputNoOutput")

    print("A2DP Agent Registered")

    manager.RequestDefaultAgent(AGENT_PATH)

    mainloop = GObject.MainLoop()
    mainloop.run()

