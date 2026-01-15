#!/bin/bash
# Apply the theme for the gemini user
su - gemini -c "kwriteconfig5 --file ~/.config/kdeglobals --group KDE --key LookAndFeelPackage --type string WinSur"

# Start the D-Bus system-wide message bus
/etc/init.d/dbus start

# Start the XRDP service
/etc/init.d/xrdp start

# Keep the container running
tail -f /dev/null
