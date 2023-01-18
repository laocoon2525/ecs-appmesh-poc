variable "family" {
  description = "Task definition family (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#family)."
  type        = string
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task."
  type        = list(string)
  default     = ["EC2", "FARGATE"]
}

variable "cpu" {
  description = "Number of cpu units used by the task."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task."
  type        = number
  default     = 512
}

variable "volumes" {
  description = "List of volumes to include in the aws_ecs_task_definition resource."
  type        = any
  default     = []
}

variable "create_task_role" {
  description = "Whether mesh-task will create the task IAM role. Defaults to true. This must be set to false when passing in an existing role using the `task_role` variable."
  type        = bool
  default     = true
}

variable "task_role" {
  description = "ECS task role to include in the task definition. You must also set `create_task_role=false` so that mesh-task knows not to create a role for you. When ACLs are enabled and the AWS IAM auth method is used, the task role must be correctly configured with an `iam:GetRole` permission to fetch itself."
  type = object({
    id  = string
    arn = string
  })
  default = {
    id  = null
    arn = null
  }
}

variable "create_execution_role" {
  description = "Whether mesh-task will create the execution IAM role. Defaults to true. This must be set to false when passing in an existing role using the `execution_role` variable."
  type        = bool
  default     = true
}

variable "execution_role" {
  description = "ECS execution role to include in the task definition. You must also set `create_execution_role=false` so that mesh-task knows not to create a role for you."
  type = object({
    id  = string
    arn = string
  })
  default = {
    id  = null
    arn = null
  }
}

variable "iam_role_path" {
  description = "The path where IAM roles will be created."
  type        = string
  default     = "/consul-ecs/"

  validation {
    error_message = "The iam_role_path must begin with '/'."
    condition     = var.iam_role_path != "" && substr(var.iam_role_path, 0, 1) == "/"
  }
}

variable "additional_task_role_policies" {
  description = "List of additional policy ARNs to attach to the task role."
  type        = list(string)
  default     = []
}

variable "additional_execution_role_policies" {
  description = "List of additional policy ARNs to attach to the execution role."
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Port that the application listens on. If the application does not listen on a port, set outbound_only to true."
  type        = number
  default     = 0
}

variable "outbound_only" {
  description = "Whether the application only makes outward requests and does not receive any requests. Must be set to true if port is 0."
  type        = bool
  default     = false
}


variable "envoy_image" {
  description = "Envoy Docker image."
  type        = string
  default     = "envoyproxy/envoy-alpine:v1.21.4"
}

variable "envoy_public_listener_port" {
  description = "The public listener port for Envoy that is used for service-to-service communication."
  type        = number
  default     = 20000

  validation {
    error_message = "The envoy_public_listener_port must be greater than 0 and less than or equal to 65535."
    condition     = var.envoy_public_listener_port > 0 && var.envoy_public_listener_port <= 65535
  }

  validation {
    error_message = "The envoy_public_listener_port must not conflict with the following ports that are reserved for Envoy: 19000."
    condition = !contains([
      19000, // envoy admin port
    ], var.envoy_public_listener_port)
  }
}

variable "log_configuration" {
  description = "Task definition log configuration object (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html)."
  type        = any
  default     = {}
}

variable "container_definitions" {
  description = "Application container definitions (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions)."
  # This is `any` on purpose. Using `list(any)` is too restrictive. It requires maps in the list to have the same key set, and same value types.
  type = any
}

variable "upstreams" {
  description = ""

  type    = any
  default = []

  validation {
    error_message = "Upstream fields 'destinationName' and 'localBindPort' are required."
    condition = alltrue(flatten([
      for upstream in var.upstreams : [
        can(lookup(upstream, "destinationName")),
        can(lookup(upstream, "localBindPort")),
      ]
    ]))
  }

  validation {
    error_message = "Upstream fields must be one of 'destinationType', 'destinationNamespace', 'destinationPartition', 'destinationName', 'datacenter', 'localBindAddress', 'localBindPort', 'config', or 'meshGateway'."
    condition = alltrue(flatten([
      for upstream in var.upstreams : [
        for key in keys(upstream) : contains(
          [
            "destinationType",
            "destinationNamespace",
            "destinationPartition",
            "destinationName",
            "datacenter",
            "localBindAddress",
            "localBindPort",
            "config",
            "meshGateway",
          ],
          key
        )
      ]
    ]))
  }
}

variable "checks" {
  description = ""

  type    = any
  default = []

  validation {
    error_message = "Check fields must be one of 'checkId', 'name', 'args', 'items', 'interval', 'timeout', 'ttl', 'http', 'header', 'method', 'body', 'tcp', 'status', 'notes', 'tlsServerName', 'tlsSkipVerify', 'grpc', 'grpcUseTls', 'h2ping', 'h2pingUseTls', 'aliasNode', 'aliasService', 'successBeforePassing', or 'failuresBeforeCritical'."
    condition = alltrue(flatten([
      for check in var.checks : [
        for key in keys(check) : contains(
          [
            "checkId",
            "name",
            "args",
            "items",
            "interval",
            "timeout",
            "ttl",
            "http",
            "header",
            "method",
            "body",
            "tcp",
            "status",
            "notes",
            "tlsServerName",
            "tlsSkipVerify",
            "grpc",
            "grpcUseTls",
            "h2ping",
            "h2pingUseTls",
            "aliasNode",
            "aliasService",
            "successBeforePassing",
            "failuresBeforeCritical",
          ],
          key
        )
      ]
    ]))
  }
}



variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "tls" {
  description = "Whether to enable TLS for the mesh-task for the control plane traffic."
  type        = bool
  default     = false
}


variable "acls" {
  description = "Whether to enable ACLs for the mesh task."
  type        = bool
  default     = false
}



variable "application_shutdown_delay_seconds" {
  type        = number
  description = <<-EOT
  An optional number of seconds by which to delay application shutdown. By default, there is no delay. This delay allows
  incoming traffic to drain off before your application container exits. This delays the TERM signal from ECS when
  the task is stopped. However, the KILL signal from ECS cannot be delayed, so this value should be shorter than the
  `stopTimeout` on the container definition. This works by setting an explicit `entryPoint` field on each container without an
  `entryPoint` field. Containers with a non-null `entryPoint` field will be ignored. Since this sets an explicit entrypoint,
  the default entrypoint from the image (if present) will not be used, so you may need to set the `command` field on the
  container definition to ensure your container starts properly, depending on your image.
  EOT
  default     = 0
}
