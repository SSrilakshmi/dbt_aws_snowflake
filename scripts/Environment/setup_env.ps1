param(
    [string]$env = "dev"
)


# Common variables (shared across environments)
$env:SNOWFLAKE_ACCOUNT = "SJANPLY-ZQC35611"
$env:SNOWFLAKE_WAREHOUSE = "COMPUTE_WH"

<#
$env:SNOWFLAKE_USERNAME = "already created as environment variable in the system, so not hardcoding here"
$env:SNOWFLAKE_PASSWORD = ""already created as environment variable in the system, so not hardcoding here"
#>

if ($env -eq "dev") {

    $env:DBT_TARGET = "dev"
    $env:DBT_THREADS = "2"

    $env:SNOWFLAKE_DATABASE = "db_airbnb_dev"    
    $env:SNOWFLAKE_ROLE = "dbt_dev_role"
  
    Write-Host "Loaded DEV environment"

}
elseif ($env -eq "test") {

    $env:DBT_TARGET = "test"
    $env:DBT_THREADS = "4"
  
    $env:SNOWFLAKE_DATABASE = "db_airbnb_test"
    $env:SNOWFLAKE_ROLE = "dbt_test_role"

    Write-Host "Loaded TEST environment"

}
elseif ($env -eq "prod") {

    $env:DBT_TARGET = "prod"
    $env:DBT_THREADS = "8"

    $env:SNOWFLAKE_DATABASE = "db_airbnb_prod"
    $env:SNOWFLAKE_ROLE = "dbt_prod_role"

    Write-Host "Loaded PROD environment"
}