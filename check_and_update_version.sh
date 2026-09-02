#!/bin/bash

# This is a script to mangle xdg/org.widelands.Widelands.metainfo.xml for beta versions
# of the Widelands flatpak package.
#
# To fix up the latest release tag, we need a release date and a version.
# There are 2 possible cases:
#
#  - Development version identified by a git commit:
#      The version string should be the output from utils/detect_revision.py, but that
#      requires the full git history to work, however, flatpak-builder tries to do a
#      shallow clone whenever it can. As a work-around, we store the version string in
#      the manifest and pass it in the WL_VERSION environment variable.
#      The date can still be taken from git.
#
#  - RC version built from source tarball:
#      The version string is stored in the WL_RELEASE file, but the date has to be set
#      in the manifest and passed in the WL_RELEASE_DATE environment variable.
#
# We identify the case by checking which variable is set.

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
sed -e 's/<release.* version="1.[0-9]*~git">'/"${WL_RELEASE_STRING}"/ \
    -e "/<binary>/d" \
    -i xdg/org.widelands.Widelands.metainfo.xml
