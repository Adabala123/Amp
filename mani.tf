provider "aws" {
  region = "${var.region}"  # Change this to your desired AWS region
}


#Deploy the Amazon EBS CSI driver
#Create an IAM role named Amazon_EBS_CSI_Driver

resource "aws_iam_role" "eks_ebs_csi_driver_role" {
  name = "AmazonEKS_EBS_CSI_Driver"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${var.oidc}:aud": "sts.amazonaws.com",
          "${var.oidc}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF
}

#Attach the AWS managed IAM policy for the EBS CSI Driver to the IAM role that you created

resource "aws_iam_role_policy_attachment" "eks_ebs_csi_driver_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_ebs_csi_driver_role.name
}


# Create the EKS addon for the Amazon EBS CSI driver
resource "aws_eks_addon" "ebs_csi_driver_addon" {
  cluster_name            = "${var.cluster_name}"  # Change this to your EKS cluster name
  addon_name              = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.eks_ebs_csi_driver_role.arn
}


#Creating a new permission policy AWSManagedPrometheusWriteAccessPolicy

resource "aws_iam_policy" "PrometheusWriteAccessPolicy" {
  name = "AWSManagedPrometheusWriteAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "aps:RemoteWrite",
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata",
        ],
        Resource = "${var.workspace_id}",
      },
    ],
  })
}


#Create an IAM role for Kubernetes service account

resource "aws_iam_role" "EKS-AMP-ServiceAccount-Role" {
  name = "EKS-AMP-ServiceAccount-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc}",
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.oidc}:sub" = "system:serviceaccount:prometheus:iamproxy-service-account",
          },
        },
      },
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc}",
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.oidc}:sub" = "system:serviceaccount:grafana:iamproxy-service-account",
          },
        },
      },
    ],
  })
}


#Attach the trust and permission policies to the role

resource "aws_iam_role_policy_attachment" "role_attachment" {
  policy_arn = aws_iam_policy.PrometheusWriteAccessPolicy.arn
  role       = aws_iam_role.EKS-AMP-ServiceAccount-Role.name
}
