#!/bin/bash

SANITY_WARNING="Exactly one of WL_VERSION or WL_RELEASE_DATE must be set."

if [ -z "$WL_RELEASE_DATE" ]
then
  if [ -z "$WL_VERSION" ]
  then
    echo "$SANITY_WARNING"
    exit 1
  fi

  # Development version

  # Check versions in manifest
  if [ "$(echo "$WL_VERSION" | sed -E 's/.*\(([0-9a-f]{7})@.*/\1/')" != \
       "$(git show --abbrev=7 --no-patch --format='%h')" ]
  then
    echo "ERROR: Mismatch of commit hash and WL_VERSION in manifest!"
    exit 1;
  fi

  # Set version string
  echo "$WL_VERSION" >WL_RELEASE

  # Get release date from git
  WL_RELEASE_DATE="$(date --date="$(git show --no-patch --format='%cI')" --utc '+%Y-%m-%d')"

else
  if [ -n "$WL_VERSION" ]
  then
    echo "$SANITY_WARNING"
    exit 1
  fi

  if [ -f WL_RELEASE ]
  then
    # RC version
    WL_VERSION="$(cat WL_RELEASE)"
  else
    echo "ERROR: WL_RELEASE is not set and WL_VERSION file is not found!"
    exit 1
  fi
fi

WL_RELEASE_STRING='<release date="'
WL_RELEASE_STRING+="${WL_RELEASE_DATE}"
WL_RELEASE_STRING+='" version="'
WL_RELEASE_STRING+="${WL_VERSION}"
WL_RELEASE_STRING+='">'

# Modify xdg/org.widelands.Widelands.metainfo.xml:
#  * Set version
#  * Remove the binary from provides, because flatpak doesn't export it
sed -e 's/<release.* version="1.3~git">'/"${WL_RELEASE_STRING}"/ \
    -e "/<binary>/d" \
    -i xdg/org.widelands.Widelands.metainfo.xml

# Validate metainfo.xml with the changes
appstreamcli validate --no-net xdg/org.widelands.Widelands.metainfo.xml

