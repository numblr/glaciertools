#!/bin/bash

# dependencies, jq and parallel:
# sudo dnf install jq
# sudo dnf install parallel
# sudo pip install awscli

set -e

############
# Constants
############

#
MB=1048576 && export MB


##########
# Utility functions: Binary data handling
# Convert binary data to lines of 256-byte hex strings
##########

# Max line size for xxd is 256
line_size=256 && export line_size

function to_hex {
  xxd -p -c "$line_size" | set_line_number
}
export -f to_hex

function to_binary {
  get_data | xxd -p -r
}
export -f to_binary

function get_line_number {
  cut -f 1
}
export -f get_line_number

function get_data {
  cut -f 2
}
export -f get_data

function set_line_number {
  cat -n
}
export -f set_line_number

function byte_range {
  hex_data="$1"

  line_numbers="$(echo -n "$1" | get_line_number | tr '\n' ' ' | tr '\t' ' ' | xargs echo -n)"
  first_line=${line_numbers%% *}
  last_line=${line_numbers##* }

  start=$(( (first_line-1)*line_size ))
  end=$(( last_line*line_size-1 ))

  # Handle last chunk
  end=$(( end > (file_size-1) ? (file_size-1) : end ))

  echo -n "$start-$end"
}
export -f byte_range


#############
# Initialize parameters and variables
#############

if [ "$#" -lt 3 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

readonly profile="$1" && export profile
readonly vault="$2" && export vault
readonly archive="$(realpath "$3")" && export archive
readonly description="${4:-}" && export description
readonly part_level=0 && export part_level

# Only powers of 2 are allowed, max is 2**22
readonly part_size=$(( 2**part_level * MB)) && export part_size

readonly file_size=$(stat -f "%z" $archive) && export file_size

echo ""
echo "---------------------------------------"
echo "Upload $archive"
echo "Total upload (bytes): $file_size"
echo "---------------------------------------"
echo ""


# initiate multipart upload connection to glacier
echo "aws --profile "$profile" \
    glacier initiate-multipart-upload \
    --account-id - \
    --part-size "$part_size" \
    --vault-name "$vault" \
    --archive-description "'$description'""

readonly init=$(aws --profile "$profile" \
    glacier initiate-multipart-upload \
    --account-id - \
    --part-size "$part_size" \
    --vault-name "$vault" \
    --archive-description "'$description'")

# xargs trims off the quotes
readonly uploadId=$(echo $init | jq '.uploadId' | xargs) && export uploadId


#########
# Upload parts
#########

echo "Start upload $uploadId"
echo ""


function upload_part {
  hex_data="$(cat)"
  range=$(byte_range "$hex_data")

  # Write part data to tmp file
  part="$(echo -n "$range" | tr '-' '_').part"
  echo -n "$hex_data" | to_binary > "$part"

  aws --profile "$profile" glacier upload-multipart-part \
    --body "$part" \
    --range "bytes $range/*" \
    --account-id - \
    --vault-name "$vault" \
    --upload-id "$uploadId"

  # Remove tmp file
  rm "$part"
}
export -f upload_part


# Number of lines of hex data per part
records=$(($part_size/$line_size)) && export records

parallel --no-notice ::: \
  'cat $archive | to_hex | parallel --no-notice --pipe -N$records upload_part' \
  './treehash $archive > treehash.sha'


#########
# Finish upload
#########

echo ""
echo "Complete upload $uploadId :"
echo ""


readonly treehash="$(cat "treehash.sha")"
readonly result=$(aws glacier --profile "$profile" complete-multipart-upload \
    --checksum "$treehash" \
    --archive-size "$file_size" \
    --upload-id "$uploadId" \
    --account-id - \
    --vault-name "$vault")

echo $result | jq '.'
