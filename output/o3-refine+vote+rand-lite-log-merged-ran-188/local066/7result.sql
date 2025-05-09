WITH delivered_orders AS (   -- only pizzas that were actually delivered
    SELECT c.order_id,
           c.pizza_id
    FROM   pizza_clean_customer_orders  AS c
    JOIN   pizza_clean_runner_orders    AS r
           ON r.order_id = c.order_id
    WHERE  r.cancellation IS NULL
),

-------------------------------------------------
-- break every delivered pizza’s recipe toppings
-------------------------------------------------
base_toppings AS (
    SELECT d.order_id,
           CAST(TRIM(j.value) AS INTEGER) AS topping_id,
           1                               AS qty          -- one unit per recipe topping
    FROM   delivered_orders d
    JOIN   pizza_recipes     pr  ON pr.pizza_id = d.pizza_id
    CROSS  JOIN json_each('[' || pr.toppings || ']') AS j   -- split the comma‑separated list
),

-------------------------------------------------
-- toppings a customer asked to leave OFF
-------------------------------------------------
exclusions AS (
    SELECT order_id,
           exclusions AS topping_id
    FROM   pizza_get_exclusions
    WHERE  order_id IN (SELECT order_id FROM delivered_orders)
),

-------------------------------------------------
-- extra toppings a customer asked to ADD
-------------------------------------------------
extras AS (
    SELECT order_id,
           extras        AS topping_id,
           extras_count  AS qty
    FROM   pizza_get_extras
    WHERE  order_id IN (SELECT order_id FROM delivered_orders)
),

-------------------------------------------------
-- keep recipe toppings that were NOT excluded
-------------------------------------------------
kept_toppings AS (
    SELECT b.topping_id,
           b.qty
    FROM   base_toppings b
    LEFT   JOIN exclusions e
           ON  e.order_id   = b.order_id
           AND e.topping_id = b.topping_id
    WHERE  e.topping_id IS NULL              -- null ⇒ not excluded
),

-------------------------------------------------
-- collect every topping instance (kept + extras)
-------------------------------------------------
all_toppings AS (
    SELECT topping_id, qty FROM kept_toppings
    UNION ALL
    SELECT topping_id, qty FROM extras
),

-------------------------------------------------
-- final summed quantity for each topping
-------------------------------------------------
topping_totals AS (
    SELECT topping_id,
           SUM(qty) AS total_qty
    FROM   all_toppings
    GROUP  BY topping_id
)

SELECT pt.topping_name  AS ingredient,
       tt.total_qty     AS quantity
FROM   topping_totals   tt
JOIN   pizza_toppings   pt ON pt.topping_id = tt.topping_id
ORDER  BY tt.total_qty DESC, pt.topping_name;