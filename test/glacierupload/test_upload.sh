#!/bin/bash

readonly MB=1048576
readonly TEST_SIZE=$((5*MB))

# Create test archives
head -c $TEST_SIZE < /dev/urandom > archive.test
head -c $TEST_SIZE < /dev/urandom > archive_2.test
head -c $TEST_SIZE < /dev/urandom > archive_3.test


echo ""
echo "########################"
echo "Test: Upload single file"
echo "########################"
./glacierupload -v test archive.test
echo ""
echo "Tested: Upload single file"
echo ""
echo "###########################"
echo "Test: Upload multiple files"
echo "###########################"
./glacierupload -v test *.test
echo ""
echo "Tested: Upload multiple files"
echo ""
echo "##################################"
echo "Test: Upload with a custom profile"
echo "##################################"
./glacierupload -p test-profile -v test archive.test
echo ""
echo "Tested: Upload with a custom profile"
echo ""
echo "###################################################"
echo "Test: Upload with default output format set to text"
echo "###################################################"
export AWS_DEFAULT_OUTPUT="text"
./glacierupload -v test archive.test
echo ""
echo "Tested: Upload with default output format set to text"
