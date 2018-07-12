#!/bin/bash

# Set log level to 1 or 2 less or more detailed log output
set -e
readonly log=0

readonly NL=$'\n'
readonly TAB=$'\t'


##########
# Utility functions
##########

function to_hex {
  echo -n "$1" | cut -f 2 | base64 -D | xxd -p -c 256
}

function count {
  echo -n "$1" | wc -l
}

function digest_file {
  echo "$(openssl dgst -sha256 -binary "$1" | base64)"
}

function combined_sha {
  cat <(echo -n "$1" | base64 -D) <(echo -n "$2" | base64 -D) \
      | openssl dgst -sha256 -binary | base64
}

function format {
  # Make newline characters visible
  echo -n "${1//$'\n'/~$'\n'}"
}


########
# Stack to keep track of intermediate hash values.
#
# Entry format: 'node_level\tnode_hash\n'
# e.g: 'xxx    ab37934694e3c48d5c437c904f1bf83197b5acc9a308410207b8fe89078c6df5'
########

stack=""
head=""

function push {
  push_value="$1"
  push_level="$2"

  stack="$stack$push_level$TAB$push_value$NL"

  (($log)) && echo "Push: $push_level $push_value" || :
  (($log > 1)) && echo "Stack size after push: $(count "$stack")" || :
  (($log > 1)) && echo "Stack after push:$NL$(format "$stack")" || :
}

function pop {
  pop_levels=${1:-1}

  # Use -n option to omit trailing newline from echo command
  # Re-add newline as posix command substitiution $(..) trims trailing newlines
  head="$(echo -n "$stack" | tail -n -$pop_levels)$NL"
  stack="$(echo -n "$stack" | tail -r | tail -n +$((pop_levels + 1)) | tail -r)$NL"
  if [[ ${#stack} -lt 2 ]]; then
    (($log > 1)) && echo "Clear empty stack" || :
    stack=""
  fi

  (($log)) && echo "Pop head ($pop_levels levels):$NL$(format "$head")" || :
  (($log > 1)) && echo "Stack after pop:$NL$(format "$stack")" || :
}

function peak {
  local peak_levels=${1:-1}

  head="$(echo -n "$stack" | tail -n -$peak_levels)$NL"

  (($log)) && echo "Peak head ($peak_levels levels):$NL$(format "$head")" || :
}

function head_levels_match {
  if [[ $(count "$head") -gt 2 ]]; then
    echo "Testing more than two levels is not supported"
    exit 10
  fi

  if [[ $(count "$head") -lt 2 ]]; then
    (($log)) && echo "Distinct head levels: 0" || :
    return 1
  fi

  local distinct=$(echo -n "$head" | cut -f 1 | uniq | wc -l)

  (($log)) && echo "Distinct head levels: $distinct" || :

  (( distinct == 1 ))
}

function combine_head_and_push {
  if [[ $(count "$head") -ne 2 ]]; then
    echo "Can combine only exactly two elements"
    exit 10
  fi

  local level=$(echo -n "$head" | head -n 1 | cut -f 1)
  local head_1=$(echo -n "$head" | head -n 1 | cut -f 2)
  local head_2=$(echo -n "$head" | tail -n 1 | cut -f 2)

  local combined=$(combined_sha "$head_1" "$head_2")

  (($log > 1)) && echo "Combine:$NL$(format $head_1)$NL$(format "$head_2")" || :
  (($log)) && echo "Combined SHA: $combined" || :

  push "$combined" "x$level"
}


############
# Calculate tree hash
############

for f in "$@"; do
  (($log)) && echo "Process $f" || :
  push "$(digest_file "$f")" "x"
  while peak 2 && head_levels_match; do
    pop 2 && combine_head_and_push
  done
done

# Reduce remaining stack if the tree is not symetric
while [[ $(count "$stack") -ge 2 ]]; do
  (($log)) && echo "Reduce stack: $(count "$stack")" || :
  pop 2 && combine_head_and_push
done

echo $(to_hex "$stack")
