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

resource "snowflake_database" "inventory_db" {
  name = "INVENTORY_DB"
}

resource "snowflake_warehouse" "inventory_wh" {
  name           = "INVENTORY_WH"
  warehouse_size = "xsmall"

  initially_suspended = true
  auto_resume         = true
  auto_suspend        = 60
}