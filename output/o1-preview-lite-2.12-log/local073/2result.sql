WITH order_rows AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY o.order_id, o.pizza_id) AS row_id,
        o.order_id,
        o.customer_id,
        CASE WHEN n.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
        n.pizza_name,
        o.exclusions,
        o.extras,
        o.order_time
    FROM pizza_customer_orders o
    JOIN pizza_names n ON o.pizza_id = n.pizza_id
),
standard_toppings AS (
    SELECT
        orow.row_id,
        CAST(value AS INTEGER) AS topping_id
    FROM order_rows orow
    JOIN pizza_recipes pr ON orow.pizza_id = pr.pizza_id
    JOIN json_each('[' || pr.toppings || ']')
),
exclusion_toppings AS (
    SELECT
        orow.row_id,
        CAST(value AS INTEGER) AS topping_id
    FROM order_rows orow
    JOIN json_each('[' || orow.exclusions || ']')
    WHERE orow.exclusions IS NOT NULL AND TRIM(orow.exclusions) != ''
),
extra_toppings AS (
    SELECT
        orow.row_id,
        CAST(value AS INTEGER) AS topping_id
    FROM order_rows orow
    JOIN json_each('[' || orow.extras || ']')
    WHERE orow.extras IS NOT NULL AND TRIM(orow.extras) != ''
),
final_toppings AS (
    SELECT
        row_id,
        topping_id,
        COUNT(*) AS count
    FROM (
        SELECT
            st.row_id,
            st.topping_id
        FROM standard_toppings st
        LEFT JOIN exclusion_toppings et ON st.row_id = et.row_id AND st.topping_id = et.topping_id
        WHERE et.topping_id IS NULL
        UNION ALL
        SELECT
            row_id,
            topping_id
        FROM extra_toppings
    ) t
    GROUP BY row_id, topping_id
),
toppings_with_name AS (
    SELECT
        ft.row_id,
        ft.topping_id,
        ft.count,
        t.topping_name
    FROM final_toppings ft
    JOIN pizza_toppings t ON ft.topping_id = t.topping_id
),
assembled_ingredients AS (
    SELECT
        row_id,
        GROUP_CONCAT(
            CASE WHEN count > 1 THEN '2x ' || topping_name ELSE topping_name END,
            ', '
        ) AS ingredients
    FROM toppings_with_name
    GROUP BY row_id
)
SELECT
    orow.row_id,
    orow.order_id,
    orow.customer_id,
    orow.pizza_name,
    orow.pizza_name || ': ' || COALESCE(ai.ingredients, '') AS final_ingredients
FROM order_rows orow
LEFT JOIN assembled_ingredients ai ON orow.row_id = ai.row_id
ORDER BY orow.row_id;