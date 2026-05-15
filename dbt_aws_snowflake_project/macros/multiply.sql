# used in sliver_bookings
{% macro multiply(col1, col2, precision=2) %}

(
    ROUND(
        COALESCE(TRY_TO_NUMBER({{ col1 }}), 0)
        *
        COALESCE(TRY_TO_NUMBER({{ col2 }}), 0),
        {{ precision }}
    )
)

{% endmacro %}
