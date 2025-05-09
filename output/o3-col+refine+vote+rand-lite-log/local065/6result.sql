SELECT
    SUM(
        CASE
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
        END + COALESCE(e.total_extras, 0)          -- $1 for each extra topping
    ) AS total_revenue
FROM pizza_clean_customer_orders AS o
JOIN pizza_clean_runner_orders   AS r USING (order_id)
JOIN pizza_names                 AS pn USING (pizza_id)
LEFT JOIN (
    SELECT order_id,
           SUM(extras_count) AS total_extras
    FROM   pizza_get_extras
    GROUP  BY order_id
) AS e USING (order_id)
WHERE r.cancellation IS NULL;