#!/usr/bin/env bash
# Hook Stop / Notification : joue le son Warcraft 3 "travail terminé"
# Compatible WSL2 (via powershell.exe) et macOS (via afplay)

SOUND="$HOME/src/claude-config/warcraft-3-paysan-travail-termine.mp3"

if [[ "$(uname -s)" == "Darwin" ]]; then
  afplay "$SOUND" &
elif command -v powershell.exe &>/dev/null; then
  # WSL2 — détache complètement le process pour éviter que le hook parent le tue
  WIN_PATH=$(wslpath -w "$SOUND")
  setsid nohup powershell.exe -NoProfile -Command "
    Add-Type -AssemblyName presentationCore
    \$mp = New-Object System.Windows.Media.MediaPlayer
    \$mp.Open([Uri]'$WIN_PATH')
    \$mp.Play()
    Start-Sleep -Seconds 3
  " >/dev/null 2>&1 &
else
  printf '\a'
fi

exit 0
