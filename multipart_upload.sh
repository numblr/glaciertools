#!/bin/bash

# dependencies, jq and parallel:
# sudo dnf install jq
# sudo dnf install parallel
# sudo pip install awscli

set -e

if [ "$#" -lt 3 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

readonly profile="$1"
readonly vault="$2"
readonly archive="$(realpath "$3")"
readonly description="${4:-}"

# Only powers of 2 are allowed, max is 2**22
readonly part_size=$((1048576 * 2**5))
readonly tmp_dir="glacier_upload"
readonly prefix="glacier_upload_part_"
readonly load="100%"

mkdir $tmp_dir
cd $tmp_dir

echo "Splitting $archive for upload"
split -a 3 -b $part_size $archive $prefix

readonly filecount="$(ls -1 $prefix* | wc -l)"
readonly filesize=$(stat -f "%z" $archive)

echo ""
echo "---------------------------------------"
echo "Total $filecount parts to upload from $tmp_dir"
echo "Total upload (bytes): $filesize"
echo "---------------------------------------"
echo ""


# initiate multipart upload connection to glacier
readonly init=$(aws --profile "$profile" \
    glacier initiate-multipart-upload \
    --account-id - \
    --part-size "$part_size" \
    --vault-name "$vault" \
    --archive-description "'$description'")

# xargs trims off the quotes
readonly uploadId=$(echo $init | jq '.uploadId' | xargs)

echo "Start upload $uploadId"
echo ""


end=-1
for f in $prefix*; do
  start=$((end+1))
  end=$((end+part_size))
  if [ $end -ge $filesize ]; then
    end=$((filesize-1))
  fi

  echo "aws --profile $profile glacier upload-multipart-part \
--body $f \
--range 'bytes $start-$end/*' \
--account-id - \
--vault-name $vault \
--upload-id $uploadId"

done \
  | cat <(echo "../treehash $archive > ${prefix}treehash.sha") <(cat -) \
  | parallel --load $load --no-notice --bar


echo ""
echo "Complete upload $uploadId :"
echo ""


readonly treehash="$(cat "${prefix}treehash.sha")"
readonly result=$(aws glacier --profile "$profile" complete-multipart-upload \
    --checksum "$treehash" \
    --archive-size "$filesize" \
    --upload-id "$uploadId" \
    --account-id - \
    --vault-name "$vault")

echo $result | jq '.'

echo ""
cd -
echo "Removing $tmp_dir"
rm -r $tmp_dir
