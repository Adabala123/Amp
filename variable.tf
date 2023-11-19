variable "account_id" {
  description = "The account ID to host the cluster in"
}
variable "cluster_name" {
  description = "The name for the eks cluster"
}
variable "oidc" {
  description = "The oidc url for the eks cluster"
}
variable "region" {
  description = "The region to host the cluster in"
}
variable "workspace_id" {
  description = "promerheus workspace id"
}
