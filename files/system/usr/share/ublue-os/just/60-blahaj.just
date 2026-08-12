# blahaj-specific recipes, picked up automatically by ublue-os' `ujust`
# (every /usr/share/ublue-os/just/*.just file gets imported).

[group('blahaj')]
[doc('Check whether a new blahaj image is staged, without applying it')]
check-updates:
    #!/usr/bin/bash
    sudo systemctl start blahaj-update-check.service
    if [ -f /var/lib/blahaj/last-update-check.json ]; then
        rpm-ostree status
    else
        echo "No check has run yet - try again in a few seconds."
    fi

[group('blahaj')]
[doc('Re-run the Brewfile (e.g. after editing it) without waiting for next boot')]
brew-bundle:
    brew bundle --file=/usr/share/blahaj/Brewfile

[group('blahaj')]
[doc('Re-fetch the fonts fonts.sh installs at build time (Material Symbols, Noto Nerd, Libre Barcode)')]
refresh-fonts:
    sudo /usr/share/blahaj/scripts/fonts.sh

[group('blahaj')]
[doc('Toggle the idle/lock/suspend daemon on or off for this session')]
toggle-idle:
    #!/usr/bin/bash
    if systemctl --user is-active --quiet blahaj-swayidle.service; then
        systemctl --user stop blahaj-swayidle.service
        echo "Idle timeout disabled."
    else
        systemctl --user start blahaj-swayidle.service
        echo "Idle timeout enabled."
    fi
