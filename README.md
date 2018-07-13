# Bash scripts for Max OS X to upload large files to AWS Glacier

## glacierupload
**Prerequisites**

This script depends on <b>jq</b> and <b>parallel</b>.  If you are using Homebrew, then run the following:

    brew install jq
    brew install parallel

It assumes you have an AWS account, and have signed up for the glacier service
and have created a vault already.

It also assumes that you have the
<a href="http://docs.aws.amazon.com/cli/latest/userguide/installing.html">AWS Command Line Interface</a>
installed on your machine, e.g. by:

    pip install awscli

The script also assumes that you have a profile with the necessary credentials
created with the command line client:

    aws --profile myprofile configure

You can verify that your connection works by describing the vault you have created:

    aws --profile myprofile glacier describe-vault --vault-name myvault --account-id -


**Script Usage**

    glacierupload <myprofile> <myvault> <myarchive> [mydescription]

The script currently still splits <i>myarchice</i> into many parts on disk before
the upload, i.e. it requires to have sufficient disk space available and needs
write access to the directory. The part size is currently also hard coded in the
<i>multipart-upload.sh</i> script, but can increased there with the restriction
that the part size must be a power of 2 (in Megabytes) and less than 4G.

## treehash

The script calculates the top level hash of a Merkel tree (tree hash) built from
equal sized chunks of a file.

**Prerequisites**

This script depends on <b>parallel</b> and <b>openssl</b>. If you are using
Homebrew, then run the following:

    brew install openssl
    brew install parallel

**Script Usage**

    treehash [-b|--block <size>] [-a|--alg <alg>] [-v|--verbose <level>] <file>


    --block    size of the leave data blocks in bytes, defaults to 1M.
               can be postfixed with K, M, G, T, P, E, k, m, g, t, p, or e,
               see the '--block' option of the 'parallel' command for details.
    --alg      hash algorithm to use, defaults to 'sha256'. Supported
               algorithms are the ones supported by 'openssl dgst'
    --verbose  print diagnostic messages to stderr if level is large then 0

The script calculates the hash purely from the provided file and does not create
any temporary files nor does it require that the chunks of the file are present
as files on the disk.
