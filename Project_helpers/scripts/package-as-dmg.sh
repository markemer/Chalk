#!/bin/sh
if [[ -z "${PROJECT_DIR}" ]]; then
  PROJECT_DIR="/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk"
fi
if [[ -z "${PROJECT_NAME}" ]]; then
  PROJECT_NAME="Chalk"
fi
if [[ "${PROJECT_NAME}" != "Chalk" ]]; then
  PROJECT_NAME="Chalk"
fi

VERSION=$(defaults read "${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.app/Contents/Info" CFBundleShortVersionString)
VERSION2=`echo "${VERSION}" | sed "s/\\./_/g" | sed "s/\\ /-/g"`
VOLNAME="${PROJECT_NAME} ${VERSION}"
DMGNAME="${PROJECT_NAME}-${VERSION2}"
SPARSEPATH="${BUILT_PRODUCTS_DIR}/${DMGNAME}.sparseimage"
DMGPATH="${BUILT_PRODUCTS_DIR}/${DMGNAME}.dmg"
hdiutil create -fs HFS+ -ov -type SPARSE -volname "${VOLNAME}" -fsargs "-c c=64,a=16,e=16" "${SPARSEPATH}"
hdiutil attach "${SPARSEPATH}"

ditto "${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.app" "/Volumes/${VOLNAME}/${PROJECT_NAME}.app"
ditto "${PROJECT_DIR}/${PROJECT_NAME}/Resources/documentation/Licence.rtf" "/Volumes/${VOLNAME}/Licence.rtf"
ditto "${PROJECT_DIR}/${PROJECT_NAME}/Resources/documentation/Lisez-moi.rtfd" "/Volumes/${VOLNAME}/Lisez-moi.rtfd"
ditto "${PROJECT_DIR}/${PROJECT_NAME}/Resources/documentation/Read Me.rtfd" "/Volumes/${VOLNAME}/Read Me.rtfd"

hdiutil detach "/Volumes/${VOLNAME}"
hdiutil compact "${SPARSEPATH}"
SECTORS=`hdiutil resize "${SPARSEPATH}" | cut -f 1`
hdiutil resize -sectors "${SECTORS}" "${SPARSEPATH}"
hdiutil convert -imagekey zlib-level=9 -format UDZO -ov "${SPARSEPATH}" -o "${DMGPATH}"
rm -rf "${SPARSEPATH}"
