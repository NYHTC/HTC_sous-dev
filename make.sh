#! /bin/sh# make
#
# make HTC sous-dev app
#
# NYHTC. 
# 
# 2017-10-20 ( eshagdar ): created


ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

INFO_FILE="Info.plist"
SCRIPT_LIB_NAME="Script Libraries"

APP_PATH="$ROOT_DIR/HTC sous-dev.app"
APP_CONTENTS_DIR="$APP_PATH/Contents"
APP_SCRIPT_LIB_DIR="$APP_CONTENTS_DIR/Resources/$SCRIPT_LIB_NAME"

SRC_DIR="$ROOT_DIR/src"
SRC_MAIN_SCRIPT="$SRC_DIR/Scripts/main.applescript"
SRC_SCRIPT_LIBRARY_DIR="$SRC_DIR/$SCRIPT_LIB_NAME"

USER_SCRIPT_LIBRARY_DIR="$HOME/Library/$SCRIPT_LIB_NAME"


# create 'placeholder' libraries in user script library so we can compile the app
# ADDED_LIBRARIES=()
for ONE_SRC_LIB in "$SRC_SCRIPT_LIBRARY_DIR"/*; do
	ONE_LIB_NAME=$(basename -s ".applescript" "$ONE_SRC_LIB")
	ONE_SCR_LIB="$SRC_SCRIPT_LIBRARY_DIR/$ONE_LIB_NAME.applescript"
	ONE_USER_LIB="$USER_SCRIPT_LIBRARY_DIR/$ONE_LIB_NAME.scpt"

	if [ ! -f "$ONE_USER_LIB" ]; then
		$(osacompile -o "$ONE_USER_LIB" "$ONE_SCR_LIB")
		# ADDED_LIBRARIES+=("$ONE_LIB_NAME")
	fi
done


# compile app
osascript -e 'tell application "HTC sous-dev" to quit'
if [ ! -f "$APP_PATH" ]; then $(rm -rf "$APP_PATH"); fi
$(osacompile -s -o "$APP_PATH" "$SRC_MAIN_SCRIPT")


# update app resources
$(cp "$SRC_DIR/$INFO_FILE" "$APP_CONTENTS_DIR/$INFO_FILE")


# add script libraries
$(mkdir "$APP_SCRIPT_LIB_DIR")
for ONE_SRC_LIB in "$SRC_SCRIPT_LIBRARY_DIR"/*; do
	ONE_LIB_NAME=$(basename -s ".applescript" "$ONE_SRC_LIB")
	$(osacompile -o "$APP_SCRIPT_LIB_DIR/$ONE_LIB_NAME.scpt" "$SRC_SCRIPT_LIBRARY_DIR/$ONE_LIB_NAME.applescript")
done


# clean up 'placeholder' libraries
# for ONE_LIB_TO_REMOVE in "$ADDED_LIBRARIES[*]"; do
# 	echo "$ONE_LIB_TO_REMOVE"
# done