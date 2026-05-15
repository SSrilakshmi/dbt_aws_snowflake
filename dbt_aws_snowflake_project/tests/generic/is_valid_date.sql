{% test is_valid_date(model, column_name) %}

with validation as (
    select
        {{ column_name }} as date_field
    from {{ model }}
),

validation_errors as (
    select
        date_field
    from validation
    where 
        -- Fails if the date is null (optional, depends on your needs)
        date_field is null 
        -- Fails if date is before 1900-01-01 or after 2100-01-01
        or date_field < cast('1900-01-01' as date)
        or date_field > cast('2100-01-01' as date)
)

select *
from validation_errors

{% endtest %}
