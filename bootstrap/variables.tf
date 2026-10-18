variable "subscription_id" {
  type = string
}

variable "prefix" {
  description = "Krótki, unikalny prefiks: małe litery i cyfry (np. kszmodels01)"
  type        = string
}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type    = string
  default = "foundry-skills"
}

variable "github_reviewer" {
  type = string
}
