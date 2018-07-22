# Command line tools (Bash scripts) to upload large files to AWS Glacier

## glacierupload

Orchestrates a multipart upload of a file to AWS glacier.

**Prerequisites**

This script depends on <b>jq</b>, <b>openssl</b> and <b>parallel</b>. If you are
on Mac OS X and using Homebrew, then run the following:

    brew install jq
    brew install parallel
    brew install openssl

The script assumes you have an AWS account, and have signed up for the glacier
service and have created a vault already.

It also assumes that you have the
<a href="http://docs.aws.amazon.com/cli/latest/userguide/installing.html">AWS Command Line Interface</a>
installed on your machine, e.g. by:

    pip install awscli

The script requires also that the aws cli is configured with your AWS credentials.
Optionally it supports profiles setup in the aws cli by

    aws --profile myprofile configure

You can verify that your connection works by describing the vault you have created:

    aws --profile myprofile glacier describe-vault --vault-name myvault --account-id -


**Script Usage**

    glacierupload [-p|--profile <profile>] [-d|--description <description>] [-s|--split-size <level>]
                   <-v|--vault vault> <file>

    -v --vault        name of the vault to which the file should be uploaded  
    -p --profile      optional profile name to use for the upload. The profil
                      name must be configured with the aws cli client.
    -d --description  optinal description of the file
    -s --split-size   level that determines the size of the parts used for
                      uploading the file. The level can be a number between
                      0 and 22 and results in part size of (2^level) MBytes.
                      If not specified the default is 0, i.e. the file is
                      uploaded in 1MByte parts.
    -h --help         print help message

The script prints the information about the upload to the shell and
additionally stores it in a file in the directory were the script is executed.
The file name equals the original file name postfixed with the first 8 characters
of the archive id and '.upload.json'.

The script splits the file to upload on the fly and only stores parts that are
currently uploaded temporarily on disk, i.e. the amount of required free disk
space is low. The size of the individual chunks can be controlled by the --split-size
option. The number of parallel uploads is determined by parallel based on the
number of available CPUs.

## treehash

The script calculates the top level hash of a Merkel tree (tree hash) built from
equal sized chunks of a file.

**Prerequisites**

This script depends on <b>parallel</b> and <b>openssl</b>. If you are on Mac OS X
and are using Homebrew, then run the following:

    brew install openssl
    brew install parallel

It does not depend on any of the other scripts in this repository and can be
used stand-alone.

**Script Usage**

    treehash [-b|--block <size>] [-a|--alg <alg>] [-v|--verbose <level>] <file>


    -b --block       size of the leave data blocks in bytes, defaults to 1M.
                     can be postfixed with K, M, G, T, P, E, k, m, g, t, p, or e,
                     see the '--block' option of the 'parallel' command for details.
    -a --alg         hash algorithm to use, defaults to 'sha256'. Supported
                     algorithms are the ones supported by 'openssl dgst'
    -v  --verbosity  print diagnostic messages to stderr if level is large then 0:
                      * level 1: Print the entire tree
                      * level 2: Print debug information
    -h --help        print help message

The script calculates the hash purely from the provided file and does not create
any temporary files nor does it require that the chunks of the file are present
as files on the disk.
