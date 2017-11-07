#! /bin/sh# recompile
#
# recompile htcLib and HTC sous-dev
#
# NYHTC. 
# 
# 2017-10-20 ( eshagdar ): created


ROOT_SOUSDEV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$ROOT_SOUSDEV_DIR"

# pull down changes compile
git pull
. make.sh

# recompile htcLib
HTCLIB_DIR="$( osascript -e 'tell application "Finder" to return POSIX path of (folder of (path to application "htcLib") as string)')"
. "$HTCLIB_DIR/recompile.sh"
echo "you must re-allow assistive devices to 'HTC sous-dev'."

cd "$ROOT_SOUSDEV_DIR"
