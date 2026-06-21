# LOTUSim native (non-Docker) environment for the BlueBoat demo box.
# Source before any lotusim/gz/colcon command:  source ~/lotusim_ws/setup_env.sh
# Shell-aware: works from bash AND zsh (the Claude Code Bash tool runs zsh here;
# ROS2 setup.bash is bash-only, so we pick setup.zsh / setup.bash per shell).
# Target: WSL2 Ubuntu 24.04 (noble) -> ROS2 jazzy + Gazebo harmonic (gz prefix).

export LOTUSIM_WS="$HOME/lotusim_ws"
export LOTUSIM_PATH="$LOTUSIM_WS/src/LOTUSim"
export ROS_DISTRO="jazzy"
export GAZEBO_VERSION="harmonic"

export LOTUSIM_MODELS_PATH="$LOTUSIM_PATH/assets/models/"
export PATH="$LOTUSIM_PATH/physics:$LOTUSIM_PATH/launch:$PATH"
export LD_LIBRARY_PATH="$LOTUSIM_PATH/physics:${LD_LIBRARY_PATH:-}"
export FASTDDS_BUILTIN_TRANSPORTS=UDPv4

# Gazebo plugin + model search paths (populated once the workspace is built).
export GZ_SIM_SYSTEM_PLUGIN_PATH="$LOTUSIM_WS/install/lib"
export GZ_GUI_PLUGIN_PATH="$LOTUSIM_WS/install/lib"
export GZ_SIM_RESOURCE_PATH="$LOTUSIM_PATH/assets/models"

# WSLg GPU OpenGL: force the Mesa d3d12 Gallium driver (RTX 4090) instead of the
# software llvmpipe fallback. Verified: glxinfo -> "D3D12 (NVIDIA GeForce RTX 4090)".
export GALLIUM_DRIVER=d3d12
export MESA_LOADER_DRIVER_OVERRIDE=d3d12

# Source ROS + the built workspace with the right per-shell script.
if [ -n "${ZSH_VERSION:-}" ]; then _ros_ext=zsh
elif [ -n "${BASH_VERSION:-}" ]; then _ros_ext=bash
else _ros_ext=sh; fi
[ -f "/opt/ros/$ROS_DISTRO/setup.$_ros_ext" ] && . "/opt/ros/$ROS_DISTRO/setup.$_ros_ext"
[ -f "$LOTUSIM_WS/install/setup.$_ros_ext" ] && . "$LOTUSIM_WS/install/setup.$_ros_ext"
# bash-only completion helper (uses the `complete` builtin)
[ -n "${BASH_VERSION:-}" ] && [ -f "$LOTUSIM_PATH/launch/bash_completion.sh" ] && . "$LOTUSIM_PATH/launch/bash_completion.sh"
unset _ros_ext
