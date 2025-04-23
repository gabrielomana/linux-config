#!/bin/bash

cat > /etc/systemd/system/grub-btrfs@.path <<'EOF'
[Unit]
Description=Monitors Timeshift snapshots in /run/timeshift/%i/backup
DefaultDependencies=no
BindsTo=run-timeshift-%i.mount

[Path]
PathModified=/run/timeshift/%i/backup/timeshift-btrfs/snapshots

[Install]
WantedBy=run-timeshift-%i.mount
EOF
