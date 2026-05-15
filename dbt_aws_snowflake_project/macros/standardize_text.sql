# used in sliver_listings.sql to standardize text columns
{% macro standardize_text(col)%}
    initcap(trim({{ col }}))
{% endmacro %}