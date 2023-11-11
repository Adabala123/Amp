# Setup Managed Prometheus and Grafana in Eks cluster


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

# Get IODC Provider data.
      aws eks describe-cluster --name eksampcluster --query "cluster.identity.oidc.issuer" --output text
# Creating a new permission policy AWSManagedPrometheusWriteAccessPolicy
  We have to create file name like AWSManagedPrometheusWriteAccessPolicy.json and modify and copy as per your requirement
  
        {
         "Version":"2012-10-17",
         "Statement":[
            {
               "Effect":"Allow",
               "Action":[
                  "aps:RemoteWrite",
                  "aps:QueryMetrics",
                  "aps:GetSeries",
                  "aps:GetLabels",
                  "aps:GetMetricMetadata"
               ],
               "Resource":"arn:aws:aps:us-east-1:234408914382:workspace/ws-cf81ea0e-d6a4-40b3-8888-701186bb538f"
            }
         ]
      }

  Now execute below command
  
      aws iam create-policy --policy-name "AWSManagedPrometheusWriteAccessPolicy" --policy-document file://AWSManagedPrometheusWriteAccessPolicy.json

# Create an IAM role for Kubernetes service account
  First we have to create a file like **TrustPolicy.json** and modify 

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
                "oidc.eks.us-east-1.amazonaws.com/id/7F2B2EC4E79C42490CA66E029809209A:sub": "system:serviceaccount:prometheus:iamproxy-service-account"
              }
            }
          },
          {
            "Effect": "Allow",
            "Principal": {
              "Federated": "arn:aws:iam::234408914382:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/7F2B2EC4E79C42490CA66E029809209A"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
              "StringEquals": {
                "oidc.eks.us-east-1.amazonaws.com/id/7F2B2EC4E79C42490CA66E029809209A:sub": "system:serviceaccount:grafana:iamproxy-service-account"
              }
            }
          }
        ]
      }
 Now execute below command
 
        aws iam create-role --role-name "EKS-AMP-ServiceAccount-Role" --assume-role-policy-document file://TrustPolicy.json --description "SERVICE ACCOUNT IAM ROLE DESCRIPTION" --query "Role.Arn" --output text

# Attach the trust and permission policies to the role
Give your role name aand policy name in below command if you made any changes 

      aws iam attach-role-policy --role-name "EKS-AMP-ServiceAccount-Role" --policy-arn "arn:aws:iam::357171621133:policy/AWSManagedPrometheusWriteAccessPolicy"

# EKS cluster hosts an OIDC provider with a public discovery endpoint

      eksctl utils associate-iam-oidc-provider --cluster eksampcluster --approve

Note: change cluster name

# Add prometheus repo
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# Deploy prometheus server 
create a file like **amp_ingest_override_values.yaml** and modify required fields

     # amp_ingest_override_values.yaml
      serviceAccounts:
        ## Disable alert manager roles
        ##
        server:
              name: "iamproxy-service-account"
              annotations:
                  eks.amazonaws.com/role-arn: "arn:aws:iam::234408914382:role/EKS-AMP-ServiceAccount-Role"
        alertmanager:
          create: false
      
      
        ## Disable pushgateway
        ##
        pushgateway:
          create: false
      
      
      server:
        remoteWrite:
              - url: https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-cf81ea0e-d6a4-40b3-8888-701186bb538f/api/v1/remote_write
                sigv4:
                  region: us-east-1
                queue_config:
                  max_samples_per_send: 1000
                  max_shards: 200
                  capacity: 2500
      
      
        ## Use a statefulset instead of a deployment for resiliency
        ##
        statefulSet:
          enabled: true
      
      
        ## Store blocks locally for short time period only
        ##
        retention: 1h
        
      ## Disable alert manager
      ##
      alertmanager:
        enabled: false
      
      
      ## Disable pushgateway
      ##
      pushgateway:
        enabled: false
 # Create Namespace and Deploy prometheus   
        kubectl create ns prometheus
        helm install prometheus-for-amp prometheus-community/prometheus -n prometheus -f ./amp_ingest_override_values.yaml --set serviceAccounts.server.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::357171621133:role/EKS-AMP-ServiceAccount-Role" --set server.remoteWrite[0].url="https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-df62d422-be47-4032-aaea-fad52cf0eab2/api/v1/remote_write" --set server.remoteWrite[0].sigv4.region=us-east-1

 Note : Change role arn and workspace url region
