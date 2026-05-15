# used to over write the default schema name in dbt_project.yml
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }} 

    {%- endif -%}

{%- endmacro %}