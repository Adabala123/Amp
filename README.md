# Amp


# To verify that your AWS IAM OpenID Connect (OIDC) provider exists for your cluster, run the following command:
      aws eks describe-cluster --name your_cluster_name --query "cluster.identity.oidc.issuer" --output text
** Note: Replace your_cluster_name with your cluster name. **

# Verify that your IAM OIDC provider is configured:

      aws iam list-open-id-connect-providers | grep OIDC_PROVIDER_ID
 Note: Replace ID of the oidc provider with your OIDC ID. If you receive a No OpenIDConnect provider found in your account error, you must create an IAM OIDC provider.


# Create an IAM OIDC provider:

      eksctl utils associate-iam-oidc-provider --cluster my-cluster --approve 
Note: Replace my-cluster with your cluster name.
 
# Deploy the Amazon EBS CSI driver:
Create an IAM trust policy file, **vi trust-policy.json** similar to the following example:

      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Federated": "arn:aws:iam::234408914382:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/7F2B2EC4E79C42490CA66E029809209A"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
              "StringEquals": {
                "oidc.eks.us-east-1.amazonaws.com/id/7F2B2EC4E79C42490CA66E029809209A:aud": "sts.amazonaws.com",
                "oidc.eks.us-east-1.amazonaws.com/id/7F2B2EC4E79C42490CA66E029809209A:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
              }
            }
          }
        ]
      }

Note: Replace YOUR_AWS_ACCOUNT_ID with your account ID. Replace YOUR_AWS_REGION with your Region. Replace your OIDC ID with the output from creating your IAM OIDC provider.

# Create an IAM role named Amazon_EBS_CSI_Driver:

      aws iam create-role \
       --role-name AmazonEKS_EBS_CSI_Driver \
       --assume-role-policy-document file://"trust-policy.json"
       
# Attach the AWS managed IAM policy for the EBS CSI Driver to the IAM role that you created:

      aws iam attach-role-policy \
      --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
      --role-name AmazonEKS_EBS_CSI_Driver
# Deploy the Amazon EBS CSI driver.

      aws eks create-addon \
       --cluster-name my-cluster \
       --addon-name aws-ebs-csi-driver \
       --service-account-role-arn arn:aws:iam::
      YOUR_AWS_ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole
Note: Replace my-cluster with your cluster name and YOUR_AWS_ACCOUNT_ID with your account ID.

# Check that the EBS CSI driver installed successfully:

      eksctl get addon --cluster my-cluster | grep ebs
# A successfully installation returns the following output:
      aws-ebs-csi-driver    v1.20.0-eksbuild.1    ACTIVE    0    arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/AmazonEKS_EBS_CSI_Driver
