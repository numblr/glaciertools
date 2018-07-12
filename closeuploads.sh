#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

readonly profile="$1"
readonly vault="$2"

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
aws --profile "$profile" glacier list-multipart-uploads \
    --account-id - \
    --vault-name "$vault" \
  | jq '.UploadsList | .['$i'] | .MultipartUploadId' \
  | xargs -t -P4 -L1 aws --profile "$profile" glacier abort-multipart-upload \
      --account-id - \
      --vault-name "$vault" \
      --upload-id

echo ""
echo "Remaining Active Connections:"

aws --profile "$profile" glacier list-multipart-uploads \
    --account-id - \
    --vault-name "$vault" \
