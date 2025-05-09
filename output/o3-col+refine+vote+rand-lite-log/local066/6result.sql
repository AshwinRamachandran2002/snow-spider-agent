WITH delivered_orders AS (
    SELECT c.order_id,
           c.pizza_id
    FROM   pizza_clean_runner_orders AS r
    JOIN   pizza_clean_customer_orders AS c
           ON c.order_id = r.order_id
    WHERE  r.cancellation IS NULL                       -- only pizzas that were actually delivered
), 
exploded_toppings AS (
    SELECT CAST(json_extract(j.value, '$') AS INTEGER) AS topping_id
    FROM   delivered_orders AS d
    JOIN   pizza_recipes     AS pr  ON pr.pizza_id = d.pizza_id
           CROSS JOIN json_each('[' || pr.toppings || ']') AS j  -- split comma-separated string into rows
)
SELECT t.topping_name AS ingredient,
       COUNT(*)       AS quantity
FROM   exploded_toppings AS e
JOIN   pizza_toppings   AS t  ON t.topping_id = e.topping_id
GROUP  BY t.topping_name
ORDER  BY quantity DESC;