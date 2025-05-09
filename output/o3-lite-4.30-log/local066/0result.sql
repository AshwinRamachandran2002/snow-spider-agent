WITH delivered_orders AS (
    SELECT order_id
    FROM pizza_clean_runner_orders
    WHERE cancellation IS NULL
),
order_pizzas AS (
    SELECT c.order_id,
           c.pizza_id
    FROM pizza_clean_customer_orders AS c
    JOIN delivered_orders AS d
      ON d.order_id = c.order_id
),
default_toppings AS (
    -- default toppings kept after removing any exclusions
    SELECT op.order_id,
           CAST(TRIM(j.value) AS INTEGER) AS topping_id,
           1 AS qty
    FROM order_pizzas            AS op
    JOIN pizza_recipes           AS pr  ON pr.pizza_id = op.pizza_id
    CROSS JOIN json_each('[' || pr.toppings || ']') AS j
    WHERE CAST(TRIM(j.value) AS INTEGER) NOT IN (
          SELECT ex.exclusions
          FROM pizza_get_exclusions AS ex
          WHERE ex.order_id = op.order_id
    )
),
extras_toppings AS (
    -- extra toppings (use extras_count if >1)
    SELECT e.order_id,
           CAST(e.extras AS INTEGER)            AS topping_id,
           COALESCE(e.extras_count, 1)          AS qty
    FROM pizza_get_extras  AS e
    JOIN delivered_orders  AS d
      ON d.order_id = e.order_id
),
all_toppings AS (
    SELECT topping_id, qty FROM default_toppings
    UNION ALL
    SELECT topping_id, qty FROM extras_toppings
)
SELECT pt.topping_name  AS ingredient,
       SUM(at.qty)      AS total_quantity
FROM all_toppings AS at
JOIN pizza_toppings AS pt
  ON pt.topping_id = at.topping_id
GROUP BY pt.topping_name
ORDER BY total_quantity DESC, ingredient;