WITH delivered_orders AS (      -- only pizzas that were actually delivered
    SELECT r.order_id,
           c.pizza_id
    FROM   pizza_clean_runner_orders r
    JOIN   pizza_clean_customer_orders c USING(order_id)
    WHERE  r.cancellation IS NULL
),

/* -------------------------------------------
   Split every delivered pizza’s recipe string
   “1, 2, 3 …” into one row per topping id
--------------------------------------------*/
split(order_id, topping_id, rest) AS (
    SELECT  d.order_id,
            CAST( trim( substr(pr.toppings,
                               1,
                               instr(pr.toppings||',',',')-1) ) AS INTEGER)  AS topping_id,
            substr(pr.toppings||',',
                   instr(pr.toppings||',',',')+1)                         AS rest
    FROM    delivered_orders d
    JOIN    pizza_recipes   pr ON pr.pizza_id = d.pizza_id

    UNION ALL
    SELECT  order_id,
            CAST( trim( substr(rest,1, instr(rest,',')-1) ) AS INTEGER),
            substr(rest, instr(rest,',')+1)
    FROM    split
    WHERE   rest <> ''
),

/* -------------------------------------------
   Remove any toppings a customer excluded
--------------------------------------------*/
base_toppings AS (
    SELECT  s.order_id,
            s.topping_id
    FROM    split s
    LEFT JOIN pizza_get_exclusions x
           ON  s.order_id  = x.order_id
           AND s.topping_id = x.exclusions
    WHERE   x.row_id IS NULL           -- keep only those NOT excluded
),

/* quantity coming from the normal recipes (after exclusions) */
base_qty AS (
    SELECT topping_id, COUNT(*) AS qty
    FROM   base_toppings
    GROUP  BY topping_id
),

/* quantity added as “extras” */
extras_qty AS (
    SELECT  e.extras AS topping_id,
            SUM(e.extras_count) AS qty
    FROM    pizza_get_extras e
    WHERE   e.order_id IN (SELECT order_id FROM delivered_orders)
    GROUP   BY e.extras
),

/* combine base + extras */
total_qty AS (
    SELECT topping_id, SUM(qty) AS quantity
    FROM (
        SELECT * FROM base_qty
        UNION ALL
        SELECT * FROM extras_qty
    )
    GROUP BY topping_id
)

SELECT  pt.topping_name   AS ingredient,
        tq.quantity
FROM    total_qty  tq
JOIN    pizza_toppings pt ON pt.topping_id = tq.topping_id
ORDER BY tq.quantity DESC, pt.topping_name;