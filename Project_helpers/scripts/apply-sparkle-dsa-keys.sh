set -o errexit

#[ $BUILD_STYLE = Deployment ] || { echo Distribution target requires "'Deployment'" build style; false; }

if [[ -z "${PROJECT_NAME}" ]]; then
  PROJECT_NAME="Chalk"
fi
if [[ "${PROJECT_NAME}" != "Chalk" ]]; then
  PROJECT_NAME="Chalk"
fi

BUNDLESHORTVERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PROJECT_NAME.app/Contents/Info" CFBundleShortVersionString)
BUNDLESHORTVERSION2=`echo "${BUNDLESHORTVERSION}" | sed "s/\\./_/g" | sed "s/\\ /-/g"`

BUNDLEVERSION=$(defaults read "${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.app/Contents/Info" CFBundleVersion)
BUNDLEVERSION2=`echo "${BUNDLEVERSION}" | sed "s/\\./_/g" | sed "s/\\ /-/g"`

DOWNLOAD_BASE_URL="https://pierre.chachatelier.fr/chalk/downloads"
RELEASENOTES_URL="https://pierre.chachatelier.fr/chalk/downloads/chalk-changelog-en.html#version-$BUNDLESHORTVERSION"

echo "BUNDLEVERSION=<$BUNDLEVERSION>, BUNDLEVERSION2=<$BUNDLEVERSION2>"
VOLNAME="${PROJECT_NAME} ${BUNDLESHORTVERSION}"
DMGNAME="${PROJECT_NAME}-${BUNDLESHORTVERSION2}"
SPARSEPATH="${BUILT_PRODUCTS_DIR}/${DMGNAME}.sparseimage"
DMGPATH="${BUILT_PRODUCTS_DIR}/${DMGNAME}.dmg"
#ARCHIVE_FILENAME="$PROJECT_NAME $BUNDLESHORTVERSION.zip"
ARCHIVE_FILENAME="${DMGNAME}.dmg"
ARCHIVE_FILEPATH="${BUILT_PRODUCTS_DIR}/${DMGNAME}.dmg"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILENAME"
KEYCHAIN_PRIVKEY_NAME="Sparkle Chalk keys private"
echo "ARCHIVE_FILEPATH = $ARCHIVE_FILEPATH"

WD=$PWD

#cd "$BUILT_PRODUCTS_DIR"
#rm -f "$PROJECT_NAME"*.zip
#zip -qr "$ARCHIVE_FILENAME" "$PROJECT_NAME.app"

SIZE=$(stat -f %z "${ARCHIVE_FILEPATH}")
PUBDATE=$(date +"%a, %d %b %G %T %z")
PRIKEYFILE="key.pri"
security find-generic-password -g -s "${KEYCHAIN_PRIVKEY_NAME}" 2>&1 1>/dev/null | perl -pe  's/(.*)<string>(.*)<\/string>(.*)/\2/g' | perl -pe 's/\\012/\n/g' > $PRIKEYFILE
cat $PRIKEYFILE
SIGNATURE=$(openssl dgst -sha1 -binary "${ARCHIVE_FILEPATH}" | openssl dgst -dss1 -sign "${PRIKEYFILE}" | openssl enc -base64)
rm -f $PRIKEYFILE

[ $SIGNATURE ] || { echo Unable to load signing private key with name "${KEYCHAIN_PRIVKEY_NAME}" from keychain; false; }

cat << EOF
<item>
<title>Version $BUNDLESHORTVERSION</title>
<sparkle:releaseNotesLink>$RELEASENOTES_URL</sparkle:releaseNotesLink>
<pubDate>$PUBDATE</pubDate>
<enclosure
url="$DOWNLOAD_URL"
sparkle:version="$BUNDLEVERSION"
sparkle:shortVersionString="$BUNDLESHORTVERSION"
type="application/octet-stream"
length="$SIZE"
sparkle:dsaSignature="$SIGNATURE"
/>
</item>
EOF

cat > "${BUILT_PRODUCTS_DIR}/sparkle-data.rss.part" << EOF
<item>
<title>Version $BUNDLESHORTVERSION</title>
<sparkle:releaseNotesLink>$RELEASENOTES_URL</sparkle:releaseNotesLink>
<pubDate>$PUBDATE</pubDate>
<enclosure
url="$DOWNLOAD_URL"
sparkle:version="$BUNDLEVERSION"
sparkle:shortVersionString="$BUNDLESHORTVERSION"
type="application/octet-stream"
length="$SIZE"
sparkle:dsaSignature="$SIGNATURE"
/>
</item>
EOF
