#!/bin/bash

# set -e
# Debug
# set -x

if [ "$#" -lt 1 ]; then
    echo "No vault specified"
    exit 1
fi

readonly vault="$1"
readonly profile="${2:-}"

echo ""
echo "Closing active Connections"


# Result of > aws glacier list-multipart-uploads
# {
#     "UploadsList": [
#         {
#             "MultipartUploadId": "RPI2Y4chvSaw1r19wVP717hghGEIV07i6WicIoNRj-6C1WBhSzAT4FRf-g0hGm8JvKWBE-vlSvTolospe9c-TCCViv_H",
#              ...
#              "VaultARN": "arn:aws:glacier:eu-west-1:190631152724:vaults/test"
#         },
#         {
#             "MultipartUploadId": "BwqY0NTHjTX6bI8s8YlF0l2on9GYOwpXKO1L4RLEl0Bf5hrPBd9XB29zra1di3lLE6Mi5WU-ouTcDEWCqdjpqBb5d7lK",
#              ...
#             "VaultARN": "arn:aws:glacier:eu-west-1:190631152724:vaults/test"
#         }
#     ]
# }
list_args=()
if [[ -n "$profile" ]]; then
  list_args+=('--profile')
  list_args+=("$profile")
fi
list_args+=('glacier' 'list-multipart-uploads')
list_args+=('--account-id' '-')
list_args+=('--vault-name')
list_args+=("$vault")

abort_args=()
if [[ -n "$profile" ]]; then
  abort_args+=('--profile')
  abort_args+=("$profile")
fi
abort_args+=('glacier' 'abort-multipart-upload')
abort_args+=('--account-id' '-')
abort_args+=('--vault-name')
abort_args+=("$vault")
abort_args+=('--upload-id')
abort_args+=('--output')
abort_args+=('json')


aws "${list_args[@]}" \
  | jq '.UploadsList | .['$i'] | .MultipartUploadId' \
  | xargs -t -P4 -L1 aws "${abort_args[@]}"

echo ""
echo "Remaining Active Connections:"

aws "${list_args[@]}"
