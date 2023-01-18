locals {
  require_port_unless_no_port_true                          = !var.outbound_only && var.port == 0 ? file("ERROR: port must be set if outbound_only is false") : null
  require_no_additional_task_policies_with_passed_role      = (!var.create_task_role && length(var.additional_task_role_policies) > 0) ? file("ERROR: cannot set additional_task_role_policies when create_task_role=false") : null
  require_no_additional_execution_policies_with_passed_role = (!var.create_execution_role && length(var.additional_execution_role_policies) > 0) ? file("ERROR: cannot set additional_execution_role_policies when create_execution_role=false") : null
}
