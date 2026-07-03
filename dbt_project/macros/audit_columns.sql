{% macro audit_columns() %}
    current_timestamp() as _dbt_loaded_at,
    '{{ invocation_id }}' as _dbt_invocation_id,
    '{{ target.name }}' as _dbt_target
{% endmacro %}
