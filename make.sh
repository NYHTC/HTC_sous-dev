#! /bin/sh# make
#
# make 'HTC sous-dev' app
#
# Erik Shagdar, NYHTC
# 
# 
# 2018-09-21 ( eshagdar ): create user script library folder if needed.
# 2017-11-02 ( eshagdar ): added fmObjTrans vendor file.
# 2017-10-20 ( eshagdar ): created.


ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

INFO_FILE="Info.plist"
SCRIPT_LIB_NAME="Script Libraries"

APP_PATH="$ROOT_DIR/HTC sous-dev.app"
APP_CONTENTS_DIR="$APP_PATH/Contents"
APP_RES_DIR="$APP_CONTENTS_DIR/Resources"
APP_SCRIPT_LIB_DIR="$APP_RES_DIR/$SCRIPT_LIB_NAME"
APP_SCRIPT_SCRIPT_DIR="$APP_RES_DIR/Scripts"

SRC_DIR="$ROOT_DIR/src"
SRC_MAIN_SCRIPT="$SRC_DIR/Scripts/main.applescript"
SRC_SCRIPT_LIBRARY_DIR="$SRC_DIR/$SCRIPT_LIB_NAME"

USER_SCRIPT_LIBRARY_DIR="$HOME/Library/$SCRIPT_LIB_NAME"

VEN_DIR="$ROOT_DIR/vendor"
VEN_DIR_CLIPTOOLS="$VEN_DIR/FmClipTools"
VEN_LIB_FMOBJ="fmObjectTranslator.applescript"


# create /Users/«user»/Library/Script Libraries dir, if needed
if [ ! -d "$USER_SCRIPT_LIBRARY_DIR" ]; then mkdir "$USER_SCRIPT_LIBRARY_DIR"; fi


# create vendor dir, if needed
if [ ! -d "$VEN_DIR" ]; then mkdir "$VEN_DIR"; fi


# update vendor libraries
if [ ! -d "$VEN_DIR_CLIPTOOLS" ]; then
	cd "$VEN_DIR"
	git clone https://github.com/DanShockley/FmClipTools.git
fi
cd "$VEN_DIR_CLIPTOOLS"
git pull > /dev/null 2>&1
cd "$ROOT_DIR"


# create 'placeholder' libraries in user script library so we can compile the app
# ADDED_LIBRARIES=()
for ONE_SRC_LIB in "$SRC_SCRIPT_LIBRARY_DIR"/*; do
	ONE_LIB_NAME=$(basename -s ".applescript" "$ONE_SRC_LIB")
	ONE_SCR_LIB="$SRC_SCRIPT_LIBRARY_DIR/$ONE_LIB_NAME.applescript"
	ONE_USER_LIB="$USER_SCRIPT_LIBRARY_DIR/$ONE_LIB_NAME.scpt"

	if [ ! -f "$ONE_USER_LIB" ]; then
		osacompile -o "$ONE_USER_LIB" "$ONE_SCR_LIB"
		# ADDED_LIBRARIES+=("$ONE_LIB_NAME")
	fi
done
# echo "created placeholder libraries"


# compile app
osascript -e 'tell application "HTC sous-dev" to quit'
if [ ! -f "$APP_PATH" ]; then $(rm -rf "$APP_PATH"); fi
osacompile -s -o "$APP_PATH" "$SRC_MAIN_SCRIPT"
# echo "compiled base app"


# update app resources
cp "$SRC_DIR/$INFO_FILE" "$APP_CONTENTS_DIR/$INFO_FILE"
cp "$VEN_DIR_CLIPTOOLS/Scripts/$VEN_LIB_FMOBJ" "$APP_SCRIPT_SCRIPT_DIR/$VEN_LIB_FMOBJ"
cp -R "$SRC_DIR/XML" "$APP_RES_DIR/"
# echo "updated resources"


# add script libraries
mkdir "$APP_SCRIPT_LIB_DIR"
for ONE_SRC_LIB in "$SRC_SCRIPT_LIBRARY_DIR"/*; do
	ONE_LIB_NAME=$(basename -s ".applescript" "$ONE_SRC_LIB")
	osacompile -o "$APP_SCRIPT_LIB_DIR/$ONE_LIB_NAME.scpt" "$SRC_SCRIPT_LIBRARY_DIR/$ONE_LIB_NAME.applescript"
done
# echo "updated script libraries"


# clean up 'placeholder' libraries
# for ONE_LIB_TO_REMOVE in "$ADDED_LIBRARIES[*]"; do
# 	echo "$ONE_LIB_TO_REMOVE"
# done


# show user the app
cd "$ROOT_DIR"
open .