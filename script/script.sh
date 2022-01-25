#!/bin/bash
env="test"
iamPolicyName="${env}EKSClusterAutoScalerPolicy"
iamRole="${env}EKSClusterAutoScalerRole"
accountId=$(aws sts get-caller-identity --query "Account" --output text)
region="us-west-2"
clusterName="test-cluster"
clusterAutoScalerImageTag="v1.20.2"
clusterOIDCProvider=$(aws eks describe-cluster --name ${clusterName} --region ${region} --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

redColor='\e[1;31m'
greenColor='\e[1;32m'
noColor='\e[0m'

# Create iam policy
cat <<EoF > ./cluster-autoscaler-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EoF


aws iam create-policy --policy-name=${iamPolicyName}  --policy-document file://./cluster-autoscaler-policy.json
if [ $? -ne 0 ]
then
  echo -e "${redColor} Policy isn't created ${noColor}"
else
  echo -e "${greenColor} Policy:${iamPolicyName} is  created ${noColor} "
fi

sleep 5


# Create trust policy
cat <<EoF > ./iam-role-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::${accountId}:oidc-provider/${clusterOIDCProvider}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${clusterOIDCProvider}:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
}
EoF

# Create iam role for service account
aws iam create-role --role-name ${iamRole} --assume-role-policy-document file://./iam-role-trust-policy.json
if [ $? -ne 0 ]
then
  echo -e "${redColor} iam Role  isn't created ${noColor}"
else
  echo -e "${greenColor} iam Role:${iamRole} is  created ${noColor} "
fi

sleep 5

# Attach policy to the role
aws iam attach-role-policy --role-name ${iamRole} --policy-arn "arn:aws:iam::${accountId}:policy/${iamPolicyName}"
if [ $? -ne 0 ]
then
  echo -e "${redColor} policy isn't attached to iam Role ${noColor}"
else
  echo -e "${greenColor} policy is attached to iam Role ${noColor} "
fi

sleep 5

# Deploy Cluster auto-sclaer component in the EKS cluster
cat <<EoF > ../cluster-autoscaler/${env}-values.yaml
serviceAccountRoleARN: arn:aws:iam::${accountId}:role/${iamRole}
clusterName: ${clusterName}
image:
  tag: ${clusterAutoScalerImageTag}
EoF

cd ../
helm -n kube-system install --values=cluster-autoscaler/${env}-values.yaml cluster-autoscaler cluster-autoscaler
if [ $? -ne 0 ]
then
  echo -e "${redColor} Cluster-autoscaler components deployment in ${clusterName} Went Wrong!!! ${noColor}"
else
  echo -e "${greenColor} Cluster-autoscaler components deployment in ${clusterName} is Successful. ${noColor} "

fi
