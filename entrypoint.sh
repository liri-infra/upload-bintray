#!/usr/bin/env sh

set -euf -o pipefail

FILENAME=$(echo "${INPUT_FILE}" | xargs -n 1 basename)

HEADER_GPG_PASSPHRASE=""
if [ "${INPUT_GPG_PASSPHRASE}" != "" ]
then
    HEADER_GPG_PASSPHRASE="X-GPG-PASSPHRASE: ${INPUT_GPG_PASSPHRASE}"
fi

HEADER_DEBIAN_DISTRIBUTION=""
if [ "${INPUT_DEB_DISTRIBUTION}" != "" ]
then
    HEADER_DEBIAN_DISTRIBUTION="X-Bintray-Debian-Distribution: ${INPUT_DEB_DISTRIBUTION}"
fi

HEADER_DEBIAN_COMPONENT=""
if [ "${INPUT_DEB_COMPONENT}" != "" ]
then
    HEADER_DEBIAN_COMPONENT="X-Bintray-Debian-Component: ${INPUT_DEB_COMPONENT}"
fi

HEADER_DEBIAN_ARCHITECTURE=""
if [ "${INPUT_DEB_ARCHITECTURE}" != "" ]
then
    HEADER_DEBIAN_ARCHITECTURE="X-Bintray-Debian-Architecture: ${INPUT_DEB_ARCHITECTURE}"
fi

if [ "${INPUT_DELETE_FILE}" = "true" ]; then
    echo "Deleting file"
    curl --silent --location \
        --user "${INPUT_API_USER}:${INPUT_API_KEY}" \
        --request DELETE \
        "${INPUT_API_URL}/content/${INPUT_REPOSITORY_USER}/${INPUT_REPOSITORY}/${FILENAME}" || /bin/true
    echo "    -> Done."
fi

if [ "${INPUT_DELETE_PACKAGE}" = "true" ]; then
    echo "Delete package"
    curl --silent --location \
        --user "${INPUT_API_USER}:${INPUT_API_KEY}" \
        --request DELETE \
        "${INPUT_API_URL}/packages/${INPUT_REPOSITORY_USER}/${INPUT_REPOSITORY}/${INPUT_PACKAGE}" || /bin/true
    echo "    -> Done."
fi

if [ "${INPUT_CREATE_PACKAGE}" = "true" ]; then
    echo "Create package"
    curl --silent --location \
        --user "${INPUT_API_USER}:${INPUT_API_KEY}" \
        --request POST \
        -H "Content-Type: application/json" \
        --data "{\"name\": \"${INPUT_PACKAGE}\", \"licenses\": [${INPUT_LICENSES}], \"vcs_url\": \"https://github.com/${GITHUB_REPOSITORY}\"}" \
        "${INPUT_API_URL}/packages/${INPUT_REPOSITORY_USER}/${INPUT_REPOSITORY}"
    echo "    -> Done."
fi

if [ "${INPUT_DELETE_VERSION}" = "true" ]; then
    echo "Deleting version"
    curl --silent --location \
        --user "${INPUT_API_USER}:${INPUT_API_KEY}" \
        --request DELETE \
        "${INPUT_API_URL}/packages/${INPUT_REPOSITORY_USER}/${INPUT_REPOSITORY}/${INPUT_PACKAGE}/versions/${INPUT_VERSION}" || /bin/true
    echo "    -> Done."
fi

if [ "${INPUT_CREATE_VERSION}" = "true" ]; then
    echo "Create version"
    curl --silent --location \
        --user "${INPUT_API_USER}:${INPUT_API_KEY}" \
        --request POST \
        -H "Content-Type: application/json" \
        --data "{\"name\": \"${INPUT_VERSION}\"}" \
        "${INPUT_API_URL}/packages/${INPUT_REPOSITORY_USER}/${INPUT_REPOSITORY}/${INPUT_PACKAGE}/versions" || /bin/true
    echo "    -> Done."
fi

echo "Uploading file"
curl --silent --show-error --fail --location --request PUT --upload-file "${1}" --user "${INPUT_API_USER}:${INPUT_API_KEY}" -H "${HEADER_GPG_PASSPHRASE}" -H "${HEADER_DEBIAN_DISTRIBUTION}" -H "${HEADER_DEBIAN_COMPONENT}" -H "${HEADER_DEBIAN_ARCHITECTURE}" "${INPUT_API_URL}/content/${INPUT_REPOSITORY_USER}/${INPUT_REPOSITORY}/${INPUT_PACKAGE}/${INPUT_VERSION}/${INPUT_UPLOAD_PATH}/${FILENAME};publish=${INPUT_PUBLISH}"
echo "    -> Done."

if [ "${INPUT_CALCULATE_METADATA}" = "true" ]
then
    echo "Requesting metadata (re)-calculation"
    curl --silent --show-error --fail --location --request POST --user "${INPUT_API_USER}:${INPUT_API_KEY}" -H "${HEADER_GPG_PASSPHRASE}" "${INPUT_API_URL}/calc_metadata/${INPUT_REPOSITORY_USER}/${INPUT_REPOSITORY}"
    echo "    -> Done."
fi
