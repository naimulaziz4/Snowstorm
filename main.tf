terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-labs/snowflake"
      version = "~> 0.35"
    }
  }
}

provider "snowflake" {
  role   = "SYSADMIN"
  region = "us-east-1"
}

provider "snowflake" {
  alias  = "security_admin"
  role   = "SECURITYADMIN"
  region = "us-east-1"
}

resource "snowflake_role" "sf_role" {
  provider = snowflake.security_admin
  name     = "SF_ROLE"
}

resource "snowflake_database" "inventory_db" {
  name = "INVENTORY_DB"
}

resource "snowflake_database_grant" "inventory_db_grant" {
  provider          = snowflake.security_admin
  database_name     = snowflake_database.inventory_db.name
  privilege         = "USAGE"
  roles             = [snowflake_role.sf_role.name]
  with_grant_option = false
}

resource "snowflake_schema" "supplier" {
  database   = snowflake_database.inventory_db.name
  name       = "SUPPLIER"
  is_managed = false
}

resource "snowflake_schema_grant" "supplier_listing" {
  provider          = snowflake.security_admin
  database_name     = snowflake_database.inventory_db.name
  schema_name       = snowflake_schema.supplier.name
  privilege         = "USAGE"
  roles             = [snowflake_role.sf_role.name]
  with_grant_option = false
}

resource "snowflake_warehouse" "inventory_wh" {
  name           = "INVENTORY_WH"
  warehouse_size = "xsmall"

  initially_suspended = true
  auto_resume         = true
  auto_suspend        = 60
}

resource "snowflake_warehouse_grant" "inventory_wh_grant" {
  provider          = snowflake.security_admin
  warehouse_name    = snowflake_warehouse.inventory_wh.name
  privilege         = "USAGE"
  roles             = [snowflake_role.sf_role.name]
  with_grant_option = false
}

resource "tls_private_key" "svc_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "snowflake_user" "sf_user" {
  provider          = snowflake.security_admin
  name              = "SF_USER"
  default_warehouse = snowflake_warehouse.inventory_wh.name
  default_role      = snowflake_role.sf_role.name
  default_namespace = "${snowflake_database.inventory_db.name}.${snowflake_schema.supplier.name}"
  rsa_public_key    = substr(tls_private_key.svc_key.public_key_pem, 27, 398)
}

resource "snowflake_role_grants" "sf_role_grants" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.sf_role.name
  users     = [snowflake_user.sf_user.name]
}