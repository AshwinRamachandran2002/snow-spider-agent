SELECT 
    SUM(
        CASE pn.pizza_name
            WHEN 'Meatlovers' THEN 12          -- base price
            WHEN 'Vegetarian' THEN 10
        END
        + COALESCE(ge.total_extras, 0)          -- $1 for each extra topping
    ) AS total_income_usd
FROM   pizza_clean_customer_orders AS cco
JOIN   pizza_names                 AS pn  ON pn.pizza_id = cco.pizza_id
JOIN   pizza_clean_runner_orders   AS cro ON cro.order_id = cco.order_id
LEFT JOIN (
        SELECT order_id,
               SUM(extras_count) AS total_extras
        FROM   pizza_get_extras
        GROUP BY order_id
) AS ge ON ge.order_id = cco.order_id
WHERE  cro.cancellation IS NULL;