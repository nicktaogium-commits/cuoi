#!/bin/sh
cd "$(dirname "$0")" || exit 1
[ -f dist/CroakSquad.jar ] || sh build.sh
exec java -Dfile.encoding=UTF-8 -cp dist/CroakSquad.jar croaksquad.server.ServerMain "$@"
