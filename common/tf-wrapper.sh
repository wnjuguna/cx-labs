#! /bin/bash

tfdir="$1"
verb="$2"
project="$3"

if which tofu > /dev/null; then
  tf=tofu
elif which terraform > /dev/null; then
  tf=terraform
else
  echo "> Neither 'tofu' nor 'terraform' found in \$PATH; install one of them and try again"
  exit 1
fi

if [[ "$verb" == "workspaces" ]]; then
  cd "$tfdir"
  $tf workspace list
  exit
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "No AWS credentials found, log in to AWS and copy-paste the Access keys"
  exit 1
fi

export TF_VAR_cx_data_key=$CX_DATA_KEY
export TF_VAR_cx_data_token=${CX_DATA_TOKEN:-$CX_DATA_KEY}
export TF_VAR_cx_region=$CX_REGION
export TF_VAR_cx_domain=$CX_DOMAIN

# Allow $USERNAME to override $USER so it's possible to set something custom.
if [ ! -z "$USERNAME" ]; then
  echo "> Found USERNAME env var (set to '$USERNAME'); replacing USER (was '$USER')"
  USER=$USERNAME
fi

# AMIs come from here: https://wiki.debian.org/Cloud/AmazonEC2Image/Trixie
if [ -z "$AWS_REGION" ]; then
  export TF_VAR_region="eu-north-1"
  export TF_VAR_ec2_ami="ami-0e63a5a9c1c7e5563"
else
  export TF_VAR_region=$AWS_REGION
  case $AWS_REGION in
    "eu-north-1")
      export TF_VAR_ec2_ami="ami-0e63a5a9c1c7e5563"
      ;;
    "us-east-1")
      export TF_VAR_ec2_ami="ami-0f9c27b471bdcd702"
      ;;
    "us-east-2")
      export TF_VAR_ec2_ami="ami-050352a65e954abb1"
      ;;
    "us-west-1")
      export TF_VAR_ec2_ami="ami-0157ed312f9c59a91"
      ;;
    "us-west-2")
      export TF_VAR_ec2_ami="ami-081ac37fe26dacc98"
      ;;
    *)
      echo "No AMI for AWS region '$AWS_REGION'"
      ;;
  esac
fi
echo "> Region: $TF_VAR_region, AMI: $TF_VAR_ec2_ami"

if [ -z "$USER" ]; then
  export TF_VAR_user="$(hostname -f)"
  echo "> Couldn't find a username configured. Using hostname ('$TF_VAR_user') instead"
else
  export TF_VAR_user=$USER
fi

export TF_VAR_aws_ssh_key_name=$TF_VAR_user
echo "> AWS SSH key name: $TF_VAR_aws_ssh_key_name"

export TF_VAR_lab_type="$project"

if [ -z "$EKS_VERSION" ]; then
  source ../common/scripts/get-default-eks-version.sh
  export EKS_VERSION=$eks_version
fi

export TF_VAR_eks_k8s_version=$EKS_VERSION
echo "> EKS Version: $TF_VAR_eks_k8s_version"

source ../common/scripts/get-default-vpc.sh
export TF_VAR_vpc_id=$TF_VAR_vpc_id
export TF_VAR_subnet_ids=$(echo '["'$TF_VAR_subnet_ids'"]' | sed 's/,/","/g')
echo "> VPC: $TF_VAR_vpc_id; Subnets: $TF_VAR_subnet_ids"

#TODO: Find the default ssh key better, surely I can ask SSH this?
if [ ! -z $AWS_SSH_PUBKEY ]; then
  export TF_VAR_public_ssh_key_path=$AWS_SSH_PUBKEY
  export TF_VAR_private_ssh_key_path=$AWS_SSH_PRIVKEY
elif [ -f ~/.ssh/id_rsa.pub ]; then
  export TF_VAR_public_ssh_key_path=~/.ssh/id_rsa.pub
  export TF_VAR_private_ssh_key_path=~/.ssh/id_rsa
elif [ -f ~/.ssh/id_ed25519.pub ]; then
  export TF_VAR_public_ssh_key_path=~/.ssh/id_ed25519.pub
  export TF_VAR_private_ssh_key_path=~/.ssh/id_ed25519
fi
echo "> Found SSH keypair: $TF_VAR_public_ssh_key_path and $TF_VAR_private_ssh_key_path"

# ECS: The cluster name must consist of alphanumerics, hyphens, and underscores.
thing_name="cs-tam-${TF_VAR_user}-$project"
export TF_VAR_thing_name="${thing_name/./-}"
echo "> Thing name: $TF_VAR_thing_name"

echo "${VERSIONNUMBERNAME/./_}"


if [ ! -z "$CX_TEAM_NAME" ]; then
  export TF_VAR_name_suffix="-$CX_TEAM_NAME"
  echo "> Name suffix: $TF_VAR_name_suffix"
elif [ ! -z "$CX_LABS_NAME_SUFFIX" ]; then
  export TF_VAR_name_suffix="-$CX_LABS_NAME_SUFFIX"
  echo "> Name suffix: $TF_VAR_name_suffix"
fi

echo "> cding to tfdir at $tfdir"
cd $tfdir

echo "> $tf ${verb}ing a thing called '$TF_VAR_thing_name${TF_VAR_name_suffix}', created by '$TF_VAR_user'"

sleep 3

if [[ -z "$CX_LABS_WORKSPACE_NAME" && ! -z "$CX_TEAM_NAME" ]]; then
  CX_LABS_WORKSPACE_NAME=$CX_TEAM_NAME
fi

if [ ! -z "$CX_LABS_WORKSPACE_NAME" ]; then
  echo "> Chosen tf workspace: $CX_LABS_WORKSPACE_NAME"
  $tf workspace select --or-create "$CX_LABS_WORKSPACE_NAME"
else
  $tf workspace select default
fi

if [[ "$verb" == "up" ]]; then
  $tf init --upgrade && $tf apply --auto-approve
elif [[ "$verb" == "plan" ]]; then
  $tf init --upgrade && $tf plan
elif [[ "$verb" == "down" ]]; then
  $tf init --upgrade && $tf destroy -auto-approve
  if [ ! -z "$CX_LABS_WORKSPACE_NAME" ]; then
    $tf workspace select default
    $tf workspace delete "$CX_LABS_WORKSPACE_NAME"
  fi

else
  echo "Invalid verb '$verb'; should be one of 'up', 'plan' or 'down'"
  exit 1;
fi
