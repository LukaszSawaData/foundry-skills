variable "subscription_id" { type = string }
variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }

variable "deployments" {
  description = "Modele do wdrożenia: klucz = nazwa deploymentu"
  type = map(object({
    model_name    = string
    model_version = string
    sku           = optional(string, "GlobalStandard")
    capacity      = number
  }))

  validation {
    condition     = alltrue([for k, _ in var.deployments : can(regex("^[a-z0-9][a-z0-9-]{1,62}$", k))])
    error_message = "Nazwa deploymentu: małe litery, cyfry i myślniki, 2-63 znaki."
  }

  validation {
    condition     = alltrue([for d in values(var.deployments) : d.capacity >= 1 && d.capacity <= 100])
    error_message = "capacity musi być w zakresie 1-100 (limit chroniący przed kosztami)."
  }
}
