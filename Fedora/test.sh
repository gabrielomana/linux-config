#!/bin/bash
    sudo tee /etc/systemd/system/grub-btrfs@.path > /dev/null <<'EOF'
[Unit]
Description=Monitors Timeshift snapshots in /run/timeshift/%i/backup
DefaultDependencies=no
BindsTo=run-timeshift-%i.mount

[Path]
PathModified=/run/timeshift/%i/backup/timeshift-btrfs/snapshots

[Install]
WantedBy=run-timeshift-%i.mount
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable --now grub-btrfs@backup.path || error "Fallo al activar grub-btrfs@backup.path"

