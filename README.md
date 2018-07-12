# Bash for Max OS X to uploading large files to AWS Glacier

**Prerequisites**

This script depends on <b>jq</b> and <b>parallel</b>.  If you are using Homebrew, then run the following:

    brew install jq
    brew install parallel

It assumes you have an AWS account, and have signed up for the glacier service and have created a vault already.

It also assumes that you have the <a href="http://docs.aws.amazon.com/cli/latest/userguide/installing.html">AWS Command Line Interface</a> installed on your machine, e.g. by:

    pip install awscli

The script also assumes that you have a profile with the necessary credentials created with the command line client:

    aws --profile myprofile configure

You can verify that your connection works by describing the vault you have created:

    aws --profile myprofile glacier describe-vault --vault-name myvault --account-id -


**Script Usage**

    glacierupload <myprofile> <myvault> <myarchive> [mydescription]
