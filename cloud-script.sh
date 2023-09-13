#!/bin/sh
# Note: script is executed as root
echo "Hello World! I'm starting up now at $(date -R)!"
echo "Script is running as user $(whoami)"

su ${username} -c "sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply the-technat"
