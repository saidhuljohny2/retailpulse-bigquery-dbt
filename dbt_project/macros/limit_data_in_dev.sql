{% macro limit_data_in_dev(column_name, dev_limit=10000) %}
    {% if target.name == 'dev' %}
        where {{ column_name }} >= date_sub(current_date(), interval {{ dev_limit }} day)
    {% endif %}
{% endmacro %}
