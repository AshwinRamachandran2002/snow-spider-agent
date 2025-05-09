WITH RECURSIVE
    delivered AS (                         -- orders that were actually delivered
        SELECT order_id
        FROM pizza_clean_runner_orders
        WHERE cancellation IS NULL
    ),
    orders_recipes AS (                    -- delivered orders matched to recipe strings
        SELECT c.order_id,
               r.toppings
        FROM pizza_clean_customer_orders AS c
        JOIN delivered USING (order_id)
        JOIN pizza_recipes AS r ON r.pizza_id = c.pizza_id
    ),
    /*---------------------------------------*
     |  Split the comma‑separated recipe list |
     *---------------------------------------*/
    base_split(order_id, topping_id, rest) AS (
        -- anchor part
        SELECT order_id,
               trim(substr(toppings,
                           1,
                           CASE
                             WHEN instr(toppings, ',') = 0
                             THEN length(toppings)
                             ELSE instr(toppings, ',') - 1
                           END))                 AS topping_id,
               ltrim(substr(toppings,
                            CASE
                              WHEN instr(toppings, ',') = 0
                              THEN length(toppings) + 1
                              ELSE instr(toppings, ',') + 1
                            END))                AS rest
        FROM orders_recipes
        UNION ALL
        -- recursive part
        SELECT order_id,
               trim(substr(rest,
                           1,
                           CASE
                             WHEN instr(rest, ',') = 0
                             THEN length(rest)
                             ELSE instr(rest, ',') - 1
                           END)),
               ltrim(substr(rest,
                            CASE
                              WHEN instr(rest, ',') = 0
                              THEN length(rest) + 1
                              ELSE instr(rest, ',') + 1
                            END))
        FROM base_split
        WHERE rest <> ''
    ),
    base_toppings AS (                      -- one row per base topping in recipe
        SELECT order_id,
               CAST(topping_id AS INTEGER) AS topping_id
        FROM base_split
        WHERE trim(topping_id) <> ''
    ),
    non_excluded AS (                       -- remove any customer exclusions
        SELECT b.order_id,
               b.topping_id
        FROM   base_toppings AS b
        LEFT JOIN (
            SELECT order_id,
                   CAST(exclusions AS INTEGER) AS topping_id
            FROM   pizza_get_exclusions
        ) AS e
          ON  b.order_id   = e.order_id
          AND b.topping_id = e.topping_id
        WHERE e.topping_id IS NULL
    ),
    extras AS (                             -- extra toppings requested
        SELECT order_id,
               CAST(extras AS INTEGER)      AS topping_id,
               COALESCE(extras_count, 1)    AS qty
        FROM   pizza_get_extras
        WHERE  order_id IN (SELECT order_id FROM delivered)
    ),
    all_toppings AS (                       -- combine base (after exclusions) and extras
        SELECT topping_id, 1  AS qty FROM non_excluded
        UNION ALL
        SELECT topping_id, qty FROM extras
    )
SELECT   pt.topping_name  AS ingredient,
         SUM(a.qty)       AS quantity
FROM     all_toppings AS a
JOIN     pizza_toppings AS pt
       ON pt.topping_id = a.topping_id
GROUP BY pt.topping_name
ORDER BY quantity DESC,
         ingredient;