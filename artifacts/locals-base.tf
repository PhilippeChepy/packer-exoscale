data "local_file" "root_ca_certificate_pem" {
  filename = "${path.module}/../artifacts/ca-certificate.pem"
}

data "local_sensitive_file" "root_ca_private_key_pem" {
  filename = "${path.module}/../artifacts/ca-certificate.key"
}

data "local_file" "root_token" {
  filename = "${path.module}/../artifacts/root-token.txt"
}

data "local_file" "inventory" {
  filename = "${path.module}/../artifacts/vault-inventory.yml"
}

locals {
  inventory_vars = yamldecode(data.local_file.inventory.content).all.vars

  base = {
    operator_security_group  = local.inventory_vars.base_operator_security_group
    exoscale_security_group  = local.inventory_vars.base_exoscale_security_group
    endpoint_loadbalencer_id = local.inventory_vars.base_endpoint_loadbalencer_id
  }

  vault = {
    client_security_group = local.inventory_vars.vault_client_security_group_id
    server_security_group = local.inventory_vars.vault_server_security_group_id
    url                   = local.inventory_vars.vault_url
    ip_address            = local.inventory_vars.vault_ip_address
    token                 = data.local_file.root_token.content
  }

  rclone = {
    vault = {
      bucket = local.inventory_vars.rclone_backup_vault_bucket
      zone   = local.inventory_vars.rclone_backup_vault_zone
    }
    etcd = {
      bucket = local.inventory_vars.rclone_backup_etcd_bucket
      zone   = local.inventory_vars.rclone_backup_etcd_zone
    }
  }
}