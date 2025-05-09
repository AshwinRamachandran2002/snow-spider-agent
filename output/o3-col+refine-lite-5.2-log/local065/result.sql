WITH extras_totals AS (
    SELECT
        order_id,
        SUM(extras_count) AS total_extras
    FROM pizza_get_extras
    GROUP BY order_id
)
SELECT
    SUM(
        CASE n.pizza_name
            WHEN 'Meatlovers' THEN 12           -- base price
            WHEN 'Vegetarian' THEN 10
        END + COALESCE(et.total_extras, 0)      -- add $1 per extra topping
    ) AS total_revenue
FROM pizza_clean_customer_orders AS c
JOIN pizza_names                AS n  USING (pizza_id)
LEFT JOIN extras_totals         AS et USING (order_id)
JOIN pizza_clean_runner_orders  AS r  USING (order_id)
WHERE r.cancellation IS NULL;