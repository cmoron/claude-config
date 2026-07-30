#!/usr/bin/env bash
# Compile click.swift à la demande, puis clique. Le binaire n'est pas versionné :
# il se reconstruit tout seul après un clone ou une modif de la source.
set -euo pipefail
d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$d/click"
if [ ! -x "$bin" ] || [ "$d/click.swift" -nt "$bin" ]; then
    swiftc -O "$d/click.swift" -o "$bin"
fi
exec "$bin" "$@"
