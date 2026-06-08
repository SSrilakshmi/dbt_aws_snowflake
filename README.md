<!-- ===================================================== -->
<!-- TABLE OF CONTENTS -->
<!-- ===================================================== -->

<details open>
<summary><h2>📚 Table of Contents</h2></summary>

- [DBT + AWS + Snowflake Data Engineering Project - Airbnb](#dbt--aws--snowflake-data-engineering-project---airbnb)
  - [Project Overview](#project-overview)
  - [Architecture](#architecture)
    - [Data Flow Diagram](#data-flow-diagram)
    - [Technologies Used](#technologies-used)
  - [Data Pipeline Layers](#data-pipeline-layers)
    - [Medallion Architecture](#medallion-architecture)
      - [Bronze Layer (Raw Data - Ingestion)](#bronze-layer-raw-data---ingestion)
      - [Silver Layer (Cleaned Data)](#silver-layer-cleaned-data)
      - [Gold Layer (Analytics)](#gold-layer-analytics)
    - [Snapshots (Slowly changing dimensions- Type 2)](#snapshots-slowly-changing-dimensions--type-2)
  - [Project Structure](#project-structure)
  - [Snowflake and VS code Setup](#snowflake-and-vs-code-setup)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
  - [Key Learning Outcomes](#key-learning-outcomes)
    - [1. Modern ELT pipeline design using](#1-modern-elt-pipeline-design-using)
    - [2. Environment-based deployment workflows](#2-environment-based-deployment-workflows)
    - [3. Reusable dbt macros for  standardization](#3-reusable-dbt-macros-for--standardization)
    - [4. Data quality enforcement](#4-data-quality-enforcement)
    - [5. Incremental loading](#5-incremental-loading)
    - [6. Slowly Changing Dimensions](#6-slowly-changing-dimensions)
    - [7. Medallion architecture](#7-medallion-architecture)
    - [8. Scalable SQL transformation architecture using Jinja](#8-scalable-sql-transformation-architecture-using-jinja)
    - [9. Dbt Parameterization](#9-dbt-parameterization)
    - [10. Data Lineage](#10-data-lineage)
    - [11. Documentation generation](#11-documentation-generation)
  - [Best practices](#best-practices)
  - [dbt Commands](#dbt-commands)
  - [Future Enhancements](#future-enhancements)

</details>

---

# DBT + AWS + Snowflake Data Engineering Project - Airbnb

---

## Project Overview


This project demonstrates an end-to-end modern data engineering workflow using **dbt**, **Snowflake**, and **AWS-integrated architecture** principles. The goal of the project is to build scalable, modular, and production-style data transformation pipelines while following software engineering best practices such as version control, environment management, testing, logging, and documentation.

The project simulates a real-world analytics engineering environment where raw data is transformed into trusted analytical models using medallion architecture (Bronze - Silver - Gold) layered dbt transformations.

## Architecture 
### Data Flow Diagram

The following diagram illustrates the end-to-end data flow of aws + dbt + Snowflake pipeline.

<img src="dbt_aws_snowflake_project\diagrams\architecture_images\dataflow.png" alt="Data Flow Architecture" width="800" height="300">



### Technologies Used

| Category | Technologies | Usage |
|---|---|---|
| Cloud Data Warehouse | Snowflake | Compute  & Storage |
| Cloud Storage | AWS  - S3, IAM | Storage, Identity and access management integration  | Message monitoring and file movement |
| Ingestion | AWS - SQS, Snowpipe | Continuously load into snowflake tables|
| Transformation Framework | dbt Core (Data Build Tool) | Modular coding, incremental models, snapshots (SCD Type 2) and custom macros for testing |
| Programming & Query Languages | SQL, Jinja | Dynamic sql code data transformation and reusability |
| Python | version 3.12+ | Interpreter |
| Scripting & Automation | PowerShell | Environment variable management and dbt target switching |
| Configuration | YAML | Configure model sources, table properties, data tests and environment variables |
| Version Control | Git & GitHub | Project tracking and managing conflicts |
| IDE & Development Tools | VS Code | Organize project, edit code, and debug |
| Documentation & Visualization | Markdown, draw.io | Created read me files and architecture diagrams

---
## Data Pipeline Layers
### Medallion Architecture
#### Bronze Layer (Raw Data - Ingestion)

<img src="dbt_aws_snowflake_project\diagrams\architecture_images\data_ingestion.png" alt="Data Ingestion" width="1300" height="550">


Raw data ingested from stage
- .csv files are staged for accessing
- secure access using snowflake **integration object** and **aws trust policy**
- snopwipe **auto ingestion** using **SQS** service
- 'bronze_bookings' - raw booking transactions
- 'bronze_hosts' - raw host data
- 'bronze_listings' - raw property listing data

#### Silver Layer (Cleaned Data)
Data quality check, cleaned and standardised data

<img src="dbt_aws_snowflake_project\diagrams\architecture_images\data_transformation.png" alt="Data Transformation" width="1400" height="600">



- 'silver_bookings' - check for unique, null, valid dates, values in range and referential integrity 
                    - data type conversion
                    - derived columns for analytics use
- 'silver_hosts' - check for unique, null, valid dates
                 - derived columns for qualitative analysis
- 'silver_listings' - check for unique, null, valid dates and referential integrity 
                    - derived column for downstream usage

#### Gold Layer (Analytics)
Analytics layer

<img src="dbt_aws_snowflake_project\diagrams\architecture_images\silver_gold.png" alt="Analytical Layer" width="1400" height="500">


-'one big table' - denormalized fact table  joining with bookings, hosts and listings
- 'booking_revenue' - for metrics and analysis related to bookings
- 'fact_airbnb' - Fact table for dimensional model
- ephimeral models for downstream usage

### Snapshots (Slowly changing dimensions- Type 2)
Tracking historical data
- 'dim_bookings' - historical data for boolings
- 'dim_hosts' - historical data for hosts
- 'dim_listiings' - historical data for listings

---

## Project Structure

```
dbt_aws_snowflake
  └── README.md                                   # This file
  └── pyproject.toml                              # Python dependencies
  └── main.py                                     # Python executon script
  └── 📁setup
      └── 📁environment
          ├── setup_env.ps1                       # script to set up environment variables
      └── 📁infrastructure
          ├── 1_airbnb_setup.sql                  # script for db, schema, tables, role, grants, stage, file_format, storage_integration and pipes for multiple environments (dev/test/prod)
          └── 2_clean_airbnb_setup.sql            # script to clean up the entire database infrastructure
  └── 📁dbt_aws_snowflake_project                # Main dbt project
    └── 📁analyses                                # ad-hoc queries for exploring the state of the tables
          ├── explore_bronze_bookings.sql
          ├── explore_bronze_hosts.sql
          ├── explore_bronze_listings.sql
          ├── explore_onebigtable.sql
          ├── explore_silver_hosts.sql
          ├── explore_silver_listings.sql
    └── 📁macros                                  # reusable sql functions
        ├── generate_schema_name.sql              # overwrites default schema to custom schema
        ├── multiply.sql                          # used in price caluclation
        ├── standardize_text.sql                  # standardise text data elements
        ├── tag_occupancy.sql                     # used to derive occupancy category
    └── 📁models/                                # dbt models
        └── 📁bronze/                            # raw data layer
            ├── bronze_bookings.sql
            ├── bronze_hosts.sql
            ├── bronze_listings.sql
            ├── properties.yml                    # perform data quality checks and asserting constraints
       └── 📁silver                              # cleaned data layer
            ├── silver_bookings.sql
            ├── silver_hosts.sql
            ├── silver_listings.sql
       └── 📁gold/                               # analytical layer
            └── 📁ephemeral/                     # CTE's
                ├── eph_bookings.sql
                ├── eph_hosts.sql
                ├── eph_listings.sql
            ├── booking_revenue.sql
            ├── fact_airbnb.sql
            ├── onebigtable.sql
        └── 📁sources                           
            ├── sources.yml                      # source definition
    └── 📁snapshots                             # tables capturing historical data (SCD Type 2)
        ├── dim_bookings.sql
        ├── dim_hosts.sql
        ├── dim_listings.sql
    └── 📁tests                                 # data quality tests
        └── 📁generic
            ├── is_valid_date.sql               # generic test for date validilty
        ├── tst_sources.sql                     # custom test for invalid values

```


## Snowflake and VS code Setup

### Prerequisites
* AWS Account
* Snowflake Account
* Python (v3.12+)
  * uv package manager
* dbt core
* VS Code

### Installation

1. Create an S3 bucket in AWS (ppairbnb)
   - Upload *.csv files
   - Create a role 
   - Create a user. Assign the user to the role.
   - Create permissions for the role
  
2. Clone Github Repository
   
    <details>
    <summary>Terminal - Powershell</summary>

    ```powershell
       mkdir dbt_aws_snowflake
      cd dbt_aws_snowflake
    
    ```
    </details>
    

3. Set up Snowflake Database
   - Run **1_airbnb_setup.sql** available in /setup/environment/infrastruture in Snowflake to create different environments, databases, roles, schemas, tables in stage, file formats, storage integration and pipes. Assign privileges to roles
      <details>

      ```sql

        -- Snippet only for dynamic pipes creation and meta data capturing for downstream
      
        FOR i IN 0 TO ARRAY_SIZE(:arr_databases) - 1 DO
        LET db VARCHAR := :arr_databases[i];

          FOR j IN 0 to ARRAY_SIZE(:arr_schemas) -1 DO
              LET sch VARCHAR := :arr_schemas[j];

              IF (:db = 'DB_AIRBNB_RAW' AND :sch = 'STAGING') THEN  -- create 3 pipes in _RAW  database
              
                  FOR k IN 0 TO ARRAY_SIZE(:arr_tables) - 1 DO
                      LET pipename VARCHAR := :arr_tables[k];
                      LET tablename VARCHAR := :arr_tables[k];
                      LET filenamepattern VARCHAR := '.*' || LOWER(:arr_tables[k]) || '.*[.]csv';  -- using Reg Expression for file name         
      
                      LET sql_stmt VARCHAR := '
                          CREATE PIPE IF NOT EXISTS ' || :db || '.' || :sch || '.' || :pipename || '_PIPE
                              AUTO_INGEST = TRUE
                              AS
                              COPY INTO ' || :db || '.' || :sch || '.' || :tablename || '
                              FROM @' || :db || '.' || :sch || '.STG_AIRBNB_S3
                              PATTERN = ''' || :filenamepattern || '''
                              FILE_FORMAT = (FORMAT_NAME = ' || :db || '.' || :sch || '.CSV_FORMAT_HEADER_METADATA)
                              MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
                              INCLUDE_METADATA = (
                                  FILENAME = METADATA$FILENAME,
                                  FILE_ROW_NUMBER = METADATA$FILE_ROW_NUMBER,
                                  FILE_CONTENT_KEY = METADATA$FILE_CONTENT_KEY,
                                  FILE_LAST_MODIFIED = METADATA$FILE_LAST_MODIFIED,
                                  START_SCAN_TIME = METADATA$START_SCAN_TIME
                              )';
                  END FOR;
              END IF;
          END FOR;
        END FOR;

      </details>
    
1. Establish Secure Connection for snowflake
   - In AWS-IAM - Establish Trust Relationship to External Id
     - obtain STORAGE_AWS_EXTERNAL_ID value using the script
        <details>

        ```sql
          DESCRIBE STORAGE INTEGRATION IO_AIRBNB;
          
        ```
        </details>

    - Edit ExternalId for IAM - Trust Policy      
      
        <details>

        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "AWS": "paste your role ARN from aws"
              },
              "Action": "sts:AssumeRole",
              "Condition": {
                "StringEquals": {
                  "sts:ExternalId": " paste your STORAGE_AWS_EXTERNAL_ID here"
                }
              }
            }
          ]
        }
        ```
      </details>

2. Ingest data from AWS - s3 to Snowflake-Stage
     - Set up **SQS** service
       - In snowflake, execute 'SHOW PIPES;'. Copy value for **notification channel**
       - In AWS - S3 (ppairbnb) - properties
         - Create event notification
         - Enter SQS queue ARN = notification channel value
            - For every new object available in ppairbnb, a notification is sent to snowpipe which auto ingests data

   
3. Create **Project** and install **Dependencies**. 
   In VS code open the project folder
   - Create new Python Project

      <details>
      <summary><strong>Terminal — PowerShell</strong></summary>

      ```powershell
        uv init

        .venv\Scripts\Activate.ps1
      ```
      </details>

   - open file .python-version - Make sure it is 3.12 (important for dbt)
  
   - Install dependencies - added to pyproject.toml [dependencies]
     
      <details>
      <summary><strong>Terminal — PowerShell</strong></summary>

      ```powershell
        uv add dbt-core

        uv add dbt-snowflake
      ```
      </details>

   -  Move the ~/.dbt/profiles.yml file to VS code project dbt_aws_snowflake_project
  
   -  Save project in Git and create a new branch      
           
      <details>
      <summary><strong>Terminal — PowerShell</strong></summary>

      ```powershell          
          git add .

          git commit -m "initial commit"

          git switch  -c dbt project connection
          
      ```
      </details>
  
  
7. Create **Environments** and **Environment variables**
     -  Under Environment Variables on your machine, create the following
        -  SNOWFLAKE_USERNAME (Assign snowflake user name)
        -  SNOWFLAKE_PASSWORD (Assign your snowflake password)  
  
     -  Modify profiles.yml file as below  
         <details>

           ```
           dbt_aws_snowflake_project:
             target: "{{ env_var('DBT_TARGET', 'dev') }}"

             outputs:
               dev:
                 account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
                 database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
                 password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
                 role: "{{ env_var('SNOWFLAKE_ROLE') }}"
                 schema: dbt_schema                                    # pseudo schema which will be overwritten 
                 threads: "{{ env_var('DBT_THREADS') | int }}"
                 type: snowflake
                 user: "{{ env_var('SNOWFLAKE_USERNAME') }}"
                 warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
               
           ```
         </details>

     - Make environment variables available for the session. Run **setup_env.ps1** in setup/environment/            

         <details>

         ```
           param(
                   [string]$env = "dev"
               )

               Write-Host ""
               Write-Host "Setting dbt environment: $env" -ForegroundColor Cyan

               # Common variables (shared across environments)
               $env:SNOWFLAKE_ACCOUNT = "your snowflake account"
               $env:SNOWFLAKE_WAREHOUSE = "COMPUTE_WH"

               <#
               $env:SNOWFLAKE_USERNAME = "already created as environment variable in the system"
               $env:SNOWFLAKE_PASSWORD = ""already created as environment variable in the system"
               #>

               # Environment-specific settings
               switch ($env.ToLower()) {

                   "dev" {
                       $env:SNOWFLAKE_DATABASE = "DB_AIRBNB_DEV"
                       $env:SNOWFLAKE_ROLE = "DBT_DEV_ROLE"
                       $env:DBT_THREADS = 1
                       $env:DBT_TARGET = "dev"
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
           ```
      </details>

    - Run script to set environment variables. Note - **dev** following the script path indicates the environment of interest
  
      <details>
      <summary><strong>Terminal — PowerShell</strong></summary>

      ```powershell
          
          . ./setup/environment/setup_env.ps1 dev
          
      ```
      </details>

      output:

        <img src="dbt_aws_snowflake_project\diagrams\architecture_images\set_environment_variables.png" alt="Data Transformation" width="800" height="300">

8. Configure sources in sources.yml
   <details>
    version: 2

    sources:
      - name: db_airbnb_raw 
        database: db_airbnb_raw  
        schema: staging
        tables:
          - name: bookings
          - name: hosts
          - name: listings
    </details>
      

## Key Learning Outcomes

This project demonstrates:

### 1. Modern ELT pipeline design using
  - AWS
  - DBT (Data Build Tool)
  - Snowflake
  - Jinja

### 2. Environment-based deployment workflows 
  
  ```powershell
      dbt build --target dev
  ```
  - Obtains Environmemt Variables Set
  - Establishes target database
  - Builds schema and table names from soures and modals
  - Final output:
      ```sql
      select *
      from DB_AIRBNB_DEV.bronze.bookings    
      
      ```
### 3. Reusable dbt macros for  standardization
  ```jinja
  # standardize for data consistency
  {% macro standardize_text(col)%}
    initcap(trim({{ col }}))
  {% endmacro %}

  ``` 
  ```sql
  select 
    {{-standardize_text('property_type') }} as property_type,
    {{- standardize_text('room_type') }} as room_type   
  from {{ ref('bronze_listings') }}
  
  ```

### 4. Data quality enforcement 
  - soure data validation
  - unique key constraints
  - check for not null
  - Referential integrity test
  - custom business rules test
  - check for accepted values
  - custome test based on business logic for non-negative values
  
    ```yml
    version: 2

      models:
        - name: bronze_bookings
          columns:
            - name: booking_status
              description: "Status of the booking (e.g., confirmed, cancelled, pending)"
              data_tests:
                - not_null
                - accepted_values:
                    arguments:
                      values: ['confirmed', 'cancelled']
    ```

### 5. Incremental loading
  ```sql
  {{
    config(
      materialized = 'incremental',
      on_schema_change='sync_all_columns'
    )
  }}

  {% if is_incremental() -%}
    where created_at > (select coalesce(max(created_at), '1900-01-01') from {{ this }})
  {% endif %}

  ```
  Final output:
  ```sql
  where created_at > (select coalesce(max(created_at), '1900-01-01') from DB_AIRBNB_DEV.bronze.bronze_bookings)

  ```

### 6. Slowly Changing Dimensions
  Track historical changes using snapshots timestamps
  - Historical data preserved for point-in-time analysis

### 7. Medallion architecture 
   - Database seperation by target / role
    Target: "DEV"
   ```
     dbt build --target dev # DB_AIRBNB_DEV
     dbt build --target test # DB_AIRBNB_TEST
     dbt build --target prod # DB_AIRBNB

   ``` 
   - Schema seperation by layer
     
  | Database | Schema | Usage |
  | --- |--- |--- |
  | DB_AIRBNB_DEV | BRONZE | Raw Layer |
  | DB_AIRBNB_DEV | SILVER | Cleaned Layer |
  | DB_AIRBNB_DEV | GOLD | Analytics Ready Layer |


### 8. Scalable SQL transformation architecture using Jinja
   - minimize code redundancy
   - easy to maintain
   - new fields / entities can be adopted with configuration modification

   ```sql
    {% set configs = 
      [
          { "table": ref('onebigtable'),
              "columns": "...",
              "alias": "..."
              "join_condition": "..."
          }
      ]
    %} 

    select 
        ...
    from ... alias
    {% for config in configs %}
        left join ... on ...
    {% endfor %}

   ```
  
### 9. Dbt Parameterization
  Improves
  - Reusability
  - Maintainability
  - Environment portability
  - Deployment flexibility
  
  | Type | Example | Benefit |
  | --- | --- | --- |
  | Environment variable parameterization | "{{ env_var('SNOWFLAKE_DATABASE') }}" | improves security |
  | Variable parameterization | {{var('start_date')}} | start date cane be accessed as needed|
  | Macro parameterization | {% macro tag_occupancy(col) %} | reusable transformation logic |


### 10. Data Lineage
  dbt tracks data lineage showing 
  - upstream dependencies
  - downstream impacts
  - modal relationships 
  - checks performed
  
### 11. Documentation generation
  ```powershell
  dbt docs generate
  
  dbt docs serve

  ```
---

## Best practices
- Role based access control (RBAC)
  ```yml
  dbt_aws_snowflake_project:
  target: "{{ env_var('DBT_TARGET', 'dev') }}"

  outputs:
    dev:
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
         
  ```

- Performance Optimization
  - incremental modals
  - ephemeral models for intermediary transformation (light weight)
  
- Code Quality
  - Git versioning
  - Code reviews for model changes


## dbt Commands

  ```powershell
  dbt debug
  dbt run
  dbt test 
  dbt docs generate
  dbt docs serve
  ```


---
## Future Enhancements
Model enhancements:
- dynamically create table structures bsed on the .csv headers /table headers
- quarantine test failures in dedicated quarantine schema
  
Business Enhancements:
- Top revenue listings	and highest earning properties
- Long stay revenue	contribution from extended stays
- Average booking value	pricing performance
- Booking frequency	popular listings
- Average stay duration




