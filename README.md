# Command line tools (Bash scripts) to upload large files to AWS Glacier

An archive containing only the scripts can be downloaded from the [releases](https://github.com/numblr/glaciertools/releases) page. Some of the scripts depend on others and assume that they are in the same directory.

## Commands
**[glacierupload](#glacierupload)**<br>
**[glacierabort](#glacierabort)**<br>
**[treehash](#treehash)**

## glacierupload

The script orchestrates the multipart upload of a large file to AWS Glacier.

**Prerequisites**

This script depends on **jq**, **openssl** and **parallel**. If you are
on Mac OS X and using Homebrew, then run the following:

    brew install jq
    brew install parallel
    brew install openssl

The script assumes you have an AWS account, and have signed up for the glacier
service and have created a vault already.

It also assumes that you have the
[AWS Command Line Interface](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
installed on your machine, e.g. by:

    pip install awscli

The script requires also that the aws cli is configured with your AWS credentials.
Optionally it supports profiles setup in the aws cli by

    aws --profile myprofile configure

You can verify that your connection works by describing the vault you have created:

    aws --profile myprofile glacier describe-vault --vault-name myvault --account-id -


**Script Usage**

    glacierupload [-p|--profile <profile>] [-d|--description <description>] [-s|--split-size <level>]
                   <-v|--vault vault> <file...>

    -v --vault        name of the vault to which the file should be uploaded  
    -p --profile      optional profile name to use for the upload. The profile
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
space is low and depends on the used chunk size and number of parallel uploads.
The size of the individual chunks can be controlled by the *--split-size* option.
The number of parallel uploads is determined by parallel based on the number of
available CPUs.

**Be aware of the [constraints](https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html#qfacts)
on the number and size of the chunks in the AWS Glacier specifications!**

In case the upload of a part fails, the script performs a number of retries. If
the upload of a part ultimately fails after the maximum number of retries, the
script aborts the upload and terminates.

**Examples**

To simply upload */path/to/my/archive* to *myvault* use

    > ./glacierupload -v myvault /path/to/my/archive

This will upload the archive in 1MByte chunks using the standard credentials
that are configured for the aws cli.

The following command

    > ./glacierupload -p my_aws_cli_profile -v myvault -s 5 -d "My favorite archive" /path/to/my/archive

will upload */path/to/my/archive* to *myvault* on AWS glacier with a short
description. The credentials that were configured in the *my_aws_cli_profile*
in the aws cli will be used. Instead of the default part size of 1MB the
archive is uploaded in 2^5=32MByte chunks.


## glacierabort

Abort (close) all unfinished uploads to a vault on AWS Glacier.

**Script Usage**

    glacierabort -v|--vault <vault> [-p|--profile <profile>]

    -v --vault        name of the vault for which uploads should be aborted  
    -p --profile      optional profile name to use. The profile name must be
                      configured with the aws cli client.
    -h --help         print help message

**Examples**

To abort all currently unfinished uploads run

    > ./glacierabort -v myvault


## treehash

The script calculates the top level hash of a Merkel tree (tree hash) built from
equal sized chunks of a file.

If possible, i.e. if multiple CPUs are available on your system, the script
parallelizes the computation of the tree hash.

The script does not depend on any of the other scripts in this repository and can
be used stand-alone.

**Prerequisites**

This script depends on **parallel** and **openssl**. If you are on Mac OS X
and are using Homebrew, then run the following:

    brew install openssl
    brew install parallel

**Script Usage**

    treehash [-b|--block <size>] [-a|--alg <alg>] [-v|--verbose <level>] <file>


    -b --block       size of the leaf data blocks in bytes, defaults to 1M.
                     can be postfixed with K, M, G, T, P, E, k, m, g, t, p, or e,
                     see the '--block' option of the 'parallel' command for details.
    -a --alg         hash algorithm to use, defaults to 'sha256'. Supported
                     algorithms are the ones supported by 'openssl dgst'
    -v  --verbosity  print diagnostic messages to stderr if level is larger than 0:
                      * level 1: Print the entire tree
                      * level 2: Print debug information
    -h --help        print help message

The script does not create any temporary files nor does it require that the chunks
of the file are present as files on the disk.

**Examples**

To calculate the tree hash of */path/to/my/archive* with a chunk size of 1MB and
the *sha-256* hash algorithm use

    > ./treehash /path/to/my/archive


## References

* O. Tange (2011): GNU Parallel - The Command-Line Power Tool, ;login: The USENIX Magazine, February 2011:42-47.
