/*  Summarise the total amount of every ingredient that went into
    pizzas which were actually delivered (i.e. runner did not cancel) */

WITH delivered AS (                         -- only orders that were delivered
    SELECT o.order_id ,
           o.pizza_id
    FROM   pizza_customer_orders AS o
    JOIN   pizza_runner_orders   AS r USING (order_id)
    WHERE  r.cancellation IS NULL
),
-- explode the comma-separated topping list for each pizza style
recipe_toppings AS (
    WITH RECURSIVE split(pizza_id, topping_id, rest) AS (
        SELECT pizza_id,
               TRIM(SUBSTR(toppings,1,INSTR(toppings||',',',')-1))               AS topping_id,
               LTRIM(SUBSTR(toppings,INSTR(toppings||',',',')+1))                AS rest
        FROM   pizza_recipes
        UNION ALL
        SELECT pizza_id,
               TRIM(SUBSTR(rest,1,INSTR(rest||',',',')-1))                       AS topping_id,
               LTRIM(SUBSTR(rest,INSTR(rest||',',',')+1))                        AS rest
        FROM   split
        WHERE  rest <> ''
    )
    SELECT pizza_id,
           CAST(topping_id AS INTEGER) AS topping_id
    FROM   split
)
SELECT  pt.topping_name          AS ingredient,
        COUNT(*)                 AS quantity
FROM    delivered          AS d
JOIN    recipe_toppings    AS rt  ON rt.pizza_id  = d.pizza_id
JOIN    pizza_toppings     AS pt  ON pt.topping_id = rt.topping_id
GROUP BY pt.topping_name
ORDER BY quantity DESC;