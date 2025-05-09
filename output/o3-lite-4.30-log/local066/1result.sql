WITH delivered_orders AS (
    SELECT order_id
    FROM   pizza_clean_runner_orders
    WHERE  cancellation IS NULL
),
order_recipes AS (
    SELECT c.order_id,
           pr.toppings
    FROM   pizza_clean_customer_orders AS c
    JOIN   delivered_orders USING (order_id)
    JOIN   pizza_recipes    AS pr USING (pizza_id)
),
split(order_id, topping_id, rest) AS (
    SELECT order_id,
           CAST(TRIM(SUBSTR(toppings || ',', 1,
                            INSTR(toppings || ',', ',') - 1)) AS INTEGER)     AS topping_id,
           TRIM(SUBSTR(toppings || ',', INSTR(toppings || ',', ',') + 1))     AS rest
    FROM   order_recipes
    UNION ALL
    SELECT order_id,
           CAST(TRIM(CASE WHEN INSTR(rest, ',') = 0
                          THEN rest
                          ELSE SUBSTR(rest, 1, INSTR(rest, ',') - 1)
                     END) AS INTEGER)                                         AS topping_id,
           TRIM(CASE WHEN INSTR(rest, ',') = 0
                     THEN ''
                     ELSE SUBSTR(rest, INSTR(rest, ',') + 1)
                END)                                                          AS rest
    FROM   split
    WHERE  rest <> ''
),
recipe_qty AS (
    SELECT topping_id, COUNT(*) AS qty
    FROM   split
    GROUP  BY topping_id
),
extras_qty AS (
    SELECT extras AS topping_id,
           SUM(extras_count) AS qty
    FROM   pizza_get_extras
    WHERE  order_id IN (SELECT order_id FROM delivered_orders)
    GROUP  BY extras
),
exclusions_qty AS (
    SELECT exclusions AS topping_id,
          -SUM(total_exclusions) AS qty
    FROM   pizza_get_exclusions
    WHERE  order_id IN (SELECT order_id FROM delivered_orders)
    GROUP  BY exclusions
),
all_movements AS (
    SELECT * FROM recipe_qty
    UNION ALL
    SELECT * FROM extras_qty
    UNION ALL
    SELECT * FROM exclusions_qty
),
totals AS (
    SELECT topping_id,
           SUM(qty) AS total_quantity
    FROM   all_movements
    GROUP  BY topping_id
)
SELECT pt.topping_name AS ingredient,
       totals.total_quantity
FROM   totals
JOIN   pizza_toppings AS pt ON pt.topping_id = totals.topping_id
WHERE  totals.total_quantity > 0
ORDER  BY totals.total_quantity DESC;