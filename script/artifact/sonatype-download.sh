#!/usr/bin/env bash

set -e;

echo "NEXUS_USER=$NEXUS_USER"
echo "NEXUS_OBJECT_GROUP_ID=$NEXUS_OBJECT_GROUP_ID"
echo "NEXUS_OBJECT_ARTIFACT_ID=$NEXUS_OBJECT_ARTIFACT_ID"
echo "NEXUS_OBJECT_VERSION=$NEXUS_OBJECT_VERSION"
echo "NEXUS_OBJECT_CLASSIFIER=$NEXUS_OBJECT_CLASSIFIER"

if [ -z "$NEXUS_OBJECT_CLASSIFIER" ]; then
    # we are looking for empty classifiers by default
    PATH_PARAM_CLASSIFIER=""
    QUERY_PARAM_CLASSIFIER=""
else
    PATH_PARAM_CLASSIFIER="-$NEXUS_OBJECT_CLASSIFIER"
    QUERY_PARAM_CLASSIFIER="&c=$NEXUS_OBJECT_CLASSIFIER"
fi

NEXUS_OBJECT_EXTENSION=${NEXUS_OBJECT_EXTENSION:-jar}
echo "NEXUS_OBJECT_EXTENSION=$NEXUS_OBJECT_EXTENSION"
NEXUS_DOWNLOAD_OUTPUT_FILE_NAME=${NEXUS_DOWNLOAD_OUTPUT_FILE_NAME:-"$NEXUS_OBJECT_ARTIFACT_ID-$NEXUS_OBJECT_VERSION$PATH_PARAM_CLASSIFIER.$NEXUS_OBJECT_EXTENSION"}
NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1=${NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1:-"$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME.sha1"}
echo "NEXUS_DOWNLOAD_OUTPUT_FILE_NAME=$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME"
echo "NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1=$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1"
SONATYPE_REPOSITORY=${SONATYPE_REPOSITORY:-releases}
echo "SONATYPE_REPOSITORY=$SONATYPE_REPOSITORY"
SONATYPE_URL=${SONATYPE_URL:-https://oss.sonatype.org}
echo "SONATYPE_URL=$SONATYPE_URL"
SONATYPE_API="service/local/artifact/maven/content?r=$SONATYPE_REPOSITORY&g=$NEXUS_OBJECT_GROUP_ID&a=$NEXUS_OBJECT_ARTIFACT_ID&e=$NEXUS_OBJECT_EXTENSION$QUERY_PARAM_CLASSIFIER&v=$NEXUS_OBJECT_VERSION";
echo "SONATYPE_API=$SONATYPE_API"
SONATYPE_API_SHA1="service/local/artifact/maven/content?r=$SONATYPE_REPOSITORY&g=$NEXUS_OBJECT_GROUP_ID&a=$NEXUS_OBJECT_ARTIFACT_ID$QUERY_PARAM_CLASSIFIER&e=$NEXUS_OBJECT_EXTENSION.sha1&v=$NEXUS_OBJECT_VERSION";
echo "SONATYPE_API_SHA1=$SONATYPE_API_SHA1"
SONATYPE_DOWNLOAD=$SONATYPE_URL/$SONATYPE_API

# NEXUS_USER null check
if [ ! -z "$NEXUS_USER" ]; then
    # we activate it (if we need)
    CURL_USER="-u $NEXUS_USER:$NEXUS_PASSWORD "
fi

curl -L $CURL_USER -X GET $SONATYPE_URL/$SONATYPE_API --output $NEXUS_DOWNLOAD_OUTPUT_FILE_NAME;
curl -L $CURL_USER -X GET $SONATYPE_URL/$SONATYPE_API_SHA1 --output $NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1;

FILE_SIZE=$(stat -c%s "$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME")
SHA1_FILE_SIZE=$(stat -c%s "$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1")
echo "$PWD/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME file downloaded, size: $FILE_SIZE bytes."
echo "$PWD/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1 file downloaded, size: $SHA1_FILE_SIZE bytes."

# checksum 
SHA1_ORIGINAL=$(cat $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1);
SHA1_FILE=$(sha1sum $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME | awk '{print $1}')
if [ "$SHA1_ORIGINAL" = "$SHA1_FILE" ]; then
    echo "Checksum OK"
else
    echo "Corrupted file!"
    exit 1
fi
