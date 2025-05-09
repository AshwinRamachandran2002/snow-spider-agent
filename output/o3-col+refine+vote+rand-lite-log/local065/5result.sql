SELECT SUM(
         CASE pc.pizza_id
              WHEN 1 THEN 12   -- Meat Lovers
              WHEN 2 THEN 10   -- Vegetarian
         END
         + COALESCE(e.total_extras,0)   -- $1 for each extra topping
       ) AS total_income
FROM   pizza_customer_orders  AS pc
JOIN   pizza_runner_orders    AS pr ON pc.order_id = pr.order_id
LEFT JOIN (
        SELECT order_id,
               SUM(extras_count) AS total_extras
        FROM   pizza_get_extras
        GROUP  BY order_id
) e ON pc.order_id = e.order_id
WHERE  pr.cancellation IS NULL;