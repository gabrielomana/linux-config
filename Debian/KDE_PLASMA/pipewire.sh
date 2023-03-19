#!/bin/bash
   deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
   deb_cn="$(echo "$deb_cn" | tr -d ' ')"

   current_cn=$(lsb_release -c | awk '{print $2}')
   current_cn="$(echo "$current_cn" | tr -d ' ')"


  if test $current_cn == $deb_cn ;then
    echo "stable"
    sudo nala install pipewire
    sudo touch /etc/pipewire/media-session.d/with-pulseaudio
    sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.* /etc/systemd/user/
    // Check for new service files with:
    systemctl --user daemon-reload
    // Disable and stop the PulseAudio service with:
    systemctl --user --now disable pulseaudio.service pulseaudio.socket
    // Enable and start the new pipewire-pulse service with:
    systemctl --user --now enable pipewire pipewire-pulse
    systemctl --user mask pulseaudio
    sudo nala libspa-0.2-bluetooth pulseaudio-module-bluetooth -y

  else
    echo "testing"
    sudo nala install wireplumber pipewire-media-session-
    systemctl --user --now enable wireplumber.service
  fi
