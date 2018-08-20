#!/bin/bash

# dependencies, jq and parallel:
# sudo dnf install jq
# sudo dnf install parallel
# sudo pip install awscli

set -e
# Debug
# set -x

############
# Constants
############

# Script location
readonly SCRIPT="$(cd "$(dirname "$0")"; pwd)"
# Number of parallel uploads
readonly JOBS="100%"

readonly MB=1048576
# Max line size for xxd is 256
readonly LINE_SIZE=256

##########
# Utility functions: Binary data handling
# Convert binary data to lines of 256-byte hex strings
##########


function to_hex {
  xxd -p -c "$LINE_SIZE" | set_line_number
}

function to_binary {
  get_data | xxd -p -r
}

function get_line_number {
  cut -f 1
}

function get_data {
  cut -f 2
}

function set_line_number {
  cat -n
}

function byte_range {
  hex_data="$1"

  line_numbers="$(echo -n "$1" | get_line_number | tr '\n' ' ' | tr '\t' ' ' | xargs echo -n)"
  first_line=${line_numbers%% *}
  last_line=${line_numbers##* }

  start=$(( (first_line-1)*LINE_SIZE ))
  end=$(( last_line*LINE_SIZE-1 ))

  # Handle last chunk
  end=$(( end > (file_size-1) ? (file_size-1) : end ))

  echo -n "$start-$end"
}

#############
# Initialize parameters and variables
#############

if [ "$#" -lt 2 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

readonly vault="$1"
readonly archive="$(cd "$(dirname "$2")"; pwd)/$(basename "$2")"
readonly split_size=${3:-0}
readonly description="${4:-}"
readonly profile="${5:-}"

# Only powers of 2 are allowed, max is 2**22
readonly part_size=$(( 2**split_size * MB))
readonly file_size=$(wc -c < "$archive")

echo ""
echo "---------------------------------------"
echo "Upload $archive"
echo "Total upload (bytes): $file_size"
echo "---------------------------------------"
echo ""

# initiate multipart upload connection to glacier
init_args=()
if [[ -n "$profile" ]]; then
  init_args+=('--profile')
  init_args+=("$profile")
fi
init_args+=('glacier' 'initiate-multipart-upload')
init_args+=('--account-id' '-')
init_args+=('--part-size' "$part_size")
init_args+=('--vault-name')
init_args+=("$vault")
init_args+=('--archive-description')
init_args+=("$description")

readonly init="$(aws "${init_args[@]}")"

# xargs trims off the quotes
readonly upload_id=$(echo "$init" | jq '.uploadId' | xargs)


#########
# Upload parts
#########

echo "Start upload $upload_id"


function upload_part {
  hex_data="$(cat)"
  range=$(byte_range "$hex_data")

  echo "Uploading range $range ($(( ${range##*-}/part_size ))/$(( file_size/part_size )))"

  # Write part data to tmp file
  part="$(echo -n "$range" | tr '-' '_').part"
  echo -n "$hex_data" | to_binary > "$part"

  upload_args=()
  if [[ -n "$profile" ]]; then
    upload_args+=('--profile')
    upload_args+=("$profile")
  fi
  upload_args+=('glacier' 'upload-multipart-part')
  upload_args+=('--account-id' '-')
  upload_args+=('--body' "$part")
  upload_args+=('--range')
  upload_args+=("bytes $range/*")
  upload_args+=('--vault-name')
  upload_args+=("$vault")
  upload_args+=('--upload-id' "$upload_id")

  aws "${upload_args[@]}"

  success=$?
  if (($success > 0)); then
    # echo "Upload of range $range failed"
    exit $succes
  fi

  echo "Finished upload of range $range"

  # Remove tmp file
  rm "$part"
}


# Create parts in a temporary directory
tmp_dir="$(mktemp -d)"
cd "$tmp_dir" || exit 1
echo "From temporary directory: $tmp_dir"
echo ""

# Number of lines of hex data per part
records=$((part_size/LINE_SIZE))

# parallel runs in a subprocess
export -f to_binary to_hex get_line_number get_data set_line_number byte_range
export -f upload_part

export SCRIPT JOBS MB LINE_SIZE
export upload_id
export records file_size part_size split_size
export profile description archive vault

parallel --no-notice --halt now,fail=1 --line-buffer ::: \
  'cat "$archive" | to_hex | parallel --no-notice --halt now,fail=1 --pipe -N$records upload_part -j $JOBS --line-buffer' \
  '"$SCRIPT"/treehash "$archive" > treehash.sha'

readonly treehash="$(< treehash.sha)"

# Return to original directory
echo -n "Returning to "
cd -
rm -rf "$tmp_dir"


#########
# Finish upload
#########

echo ""
echo "Complete upload $upload_id :"
echo ""


complete_args=()
if [[ -n "$profile" ]]; then
  complete_args+=('--profile')
  complete_args+=("$profile")
fi
complete_args+=('glacier' 'complete-multipart-upload')
complete_args+=('--account-id' '-')
complete_args+=('--checksum' "$treehash")
complete_args+=('--archive-size' "$file_size")
complete_args+=('--vault-name')
complete_args+=("$vault")
complete_args+=('--upload-id' "$upload_id")

readonly result=$(aws "${complete_args[@]}")

echo "$result" | jq '.'
readonly archive_id="$(echo "$result" | jq '.archiveId' | xargs)"
echo "$result" > "$(basename "$archive").${archive_id:0:8}.upload.json"
