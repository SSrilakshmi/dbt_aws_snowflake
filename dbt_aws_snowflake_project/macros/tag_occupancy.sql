# used in silver_listings.sql
{% macro tag_occupancy(col) %}
    case 
        when {{ col }} <= 2 then 'Low Occupancy' 
        when {{ col }} <= 5 then 'Medium Occupancy' 
        else 'High Occupancy' 
    end
{% endmacro %}