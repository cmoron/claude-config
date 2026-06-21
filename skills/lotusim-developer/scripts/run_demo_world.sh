#!/usr/bin/env bash
# Launch a LOTUSim world WITH xdyn physics.
# Starts one xdyn-for-cs co-simulation server per --port (the gz
# PhysicsInterfacePlugin is a websocket *client* and needs a server listening),
# then runs `gz sim`. Cleans up the xdyn servers on exit (kill by PID, no pkill).
#
# Usage: run_demo_world.sh <world.world> <model-relpath.yml> <port> [port...] [--headless]
#   GUI (default):  run_demo_world.sh xdyn_multithread_test.world dtmb_hull/dtmb-xdyn.yml 12345 12346
#   headless:       run_demo_world.sh xdyn_multithread_test.world dtmb_hull/dtmb-xdyn.yml 12345 12346 --headless
set -eo pipefail

source "$HOME/lotusim_ws/setup_env.sh"

world="$1"; yml="$2"; shift 2
ymlpath="$LOTUSIM_PATH/assets/models/$yml"
[ -f "$ymlpath" ] || { echo "yml introuvable: $ymlpath" >&2; exit 1; }

gui_flag="--gui"
ports=()
for arg in "$@"; do
  if [ "$arg" = "--headless" ]; then gui_flag=""; else ports+=("$arg"); fi
done
[ "${#ports[@]}" -gt 0 ] || { echo "au moins un port requis" >&2; exit 1; }

pids=()
for port in "${ports[@]}"; do
  xdyn-for-cs "$ymlpath" --address 127.0.0.1 --port "$port" --dt 0.2 \
    > "/tmp/xdyn_${port}.log" 2>&1 &
  pids+=("$!")
  echo "xdyn-for-cs :$port  pid=${pids[-1]}  (yml=$yml)"
done

cleanup() { echo "stopping xdyn servers (${pids[*]})..."; kill "${pids[@]}" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

echo "launching gz sim ${gui_flag:-headless} on $world ..."
cd "$LOTUSIM_WS"
lotusim run $gui_flag "$world"
