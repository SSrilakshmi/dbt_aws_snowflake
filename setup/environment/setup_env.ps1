param(
    [string]$env = "dev"
)

Write-Host ""
Write-Host "Setting dbt environment: $env" -ForegroundColor Cyan

# Common variables (shared across environments)
$env:SNOWFLAKE_ACCOUNT = "SNOWFLAKE_ACCOUNT"
$env:SNOWFLAKE_WAREHOUSE = "COMPUTE_WH"

<#
$env:SNOWFLAKE_USERNAME = "already created as environment variable in the system, so not hardcoding here"
$env:SNOWFLAKE_PASSWORD = ""already created as environment variable in the system, so not hardcoding here"
#>

# Environment-specific settings
switch ($env.ToLower()) {

    "dev" {
        $env:SNOWFLAKE_DATABASE = "DB_AIRBNB_DEV"
        $env:SNOWFLAKE_ROLE = "DBT_DEV_ROLE"
        $env:DBT_THREADS = 1
        $env:DBT_TARGET = "dev"
    }

    "test" {
        $env:SNOWFLAKE_DATABASE = "DB_AIRBNB_TEST"
        $env:SNOWFLAKE_ROLE = "DBT_TEST_ROLE"
        $env:DBT_THREADS = 2
        $env:DBT_TARGET = "test"
    }

    "prod" {
        $env:SNOWFLAKE_DATABASE = "DB_AIRBNB_PROD"
        $env:SNOWFLAKE_ROLE = "DBT_PROD_ROLE"
        $env:DBT_THREADS = 4
        $env:DBT_TARGET = "prod"
    }

    default {
        Write-Host "Invalid environment. Use dev/test/prod." -ForegroundColor Red
        return
    }
}

Write-Host ""
Write-Host "Environment variables set successfully." -ForegroundColor Green
Write-Host ""

Write-Host "Current Configuration:" -ForegroundColor Yellow
Write-Host "DBT_TARGET              = $env:DBT_TARGET"
Write-Host "SNOWFLAKE_DATABASE      = $env:SNOWFLAKE_DATABASE"
Write-Host "SNOWFLAKE_ROLE          = $env:SNOWFLAKE_ROLE"
Write-Host "SNOWFLAKE_WAREHOUSE     = $env:SNOWFLAKE_WAREHOUSE"
Write-Host "DBT_THREADS             = $env:DBT_THREADS" 
Write-Host ""

