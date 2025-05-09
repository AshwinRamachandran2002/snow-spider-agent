WITH delivered AS (
    SELECT co.order_id,
           co.pizza_id
    FROM   pizza_clean_customer_orders AS co
    JOIN   pizza_clean_runner_orders   AS ro
           ON co.order_id = ro.order_id
    WHERE  ro.cancellation IS NULL
      AND  ro.pickup_time IS NOT NULL
),
recipe AS (
    SELECT r.pizza_id,
           CAST(j.value AS INTEGER) AS topping_id
    FROM  (
           SELECT pizza_id,
                  '[' || REPLACE(toppings,' ','') || ']' AS toppings_json
           FROM   pizza_recipes
          ) AS r,
          json_each(r.toppings_json) AS j
),
base AS (
    SELECT d.order_id,
           recipe.topping_id,
           1 AS qty
    FROM   delivered AS d
    JOIN   recipe    ON d.pizza_id = recipe.pizza_id
),
excluded AS (
    SELECT order_id,
           exclusions AS topping_id
    FROM   pizza_get_exclusions
),
base_kept AS (
    SELECT b.*
    FROM   base AS b
    LEFT   JOIN excluded AS e
           ON  b.order_id  = e.order_id
           AND b.topping_id = e.topping_id
    WHERE  e.topping_id IS NULL
),
extras AS (
    SELECT order_id,
           extras        AS topping_id,
           extras_count  AS qty
    FROM   pizza_get_extras
),
all_toppings AS (
    SELECT topping_id, qty
    FROM   base_kept
    UNION ALL
    SELECT topping_id, qty
    FROM   extras
)
SELECT  pt.topping_name AS ingredient,
        SUM(a.qty)      AS quantity
FROM    all_toppings AS a
JOIN    pizza_toppings AS pt
       ON a.topping_id = pt.topping_id
GROUP  BY pt.topping_name
ORDER  BY quantity DESC;