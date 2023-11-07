# Amp


# To verify that your AWS IAM OpenID Connect (OIDC) provider exists for your cluster, run the following command:
      aws eks describe-cluster --name your_cluster_name --query "cluster.identity.oidc.issuer" --output text
** Note: Replace your_cluster_name with your cluster name. **
