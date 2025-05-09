WITH delivered_orders AS (                       -- only pizzas that were actually delivered
    SELECT c.order_id ,
           c.pizza_id
    FROM   pizza_clean_customer_orders  AS c
    JOIN   pizza_clean_runner_orders    AS r
           ON r.order_id = c.order_id
    WHERE  r.cancellation IS NULL
),

/* split the comma‑separated recipe string into one row per topping
   for every delivered order                                         */
recursive_split AS (
    SELECT d.order_id,
           CAST( TRIM( SUBSTR(p.toppings,1,INSTR(p.toppings||',',',')-1) ) AS INTEGER ) AS topping_id,
           SUBSTR(p.toppings||',',INSTR(p.toppings||',',',')+1)            AS rest
    FROM   delivered_orders d
    JOIN   pizza_recipes    p ON p.pizza_id = d.pizza_id

    UNION ALL

    SELECT order_id,
           CAST( TRIM( SUBSTR(rest,1,INSTR(rest,',')-1) ) AS INTEGER ),
           SUBSTR(rest,INSTR(rest,',')+1)
    FROM   recursive_split
    WHERE  rest <> ''
),

base_toppings AS (                 -- 1 copy of every topping in the original recipe
    SELECT order_id,
           topping_id
    FROM   recursive_split
),

exclusions AS (                    -- toppings the customer removed
    SELECT e.order_id,
           e.exclusions AS topping_id
    FROM   pizza_get_exclusions e
    JOIN   delivered_orders  d USING (order_id)
),

extras AS (                         -- extra toppings the customer added
    SELECT x.order_id,
           x.extras AS topping_id,
           COALESCE(x.extras_count,1) AS qty
    FROM   pizza_get_extras  x
    JOIN   delivered_orders d USING (order_id)
),

base_after_exclusions AS (          -- base recipe after removing exclusions
    SELECT b.topping_id,
           COUNT(*) AS qty
    FROM   base_toppings b
    LEFT  JOIN exclusions  e
           ON  e.order_id  = b.order_id
           AND e.topping_id = b.topping_id
    WHERE  e.topping_id IS NULL
    GROUP BY b.topping_id
),

extra_totals AS (                   -- totals coming from extras
    SELECT topping_id,
           SUM(qty) AS qty
    FROM   extras
    GROUP BY topping_id
),

totals AS (                         -- combine base + extras
    SELECT t.topping_id,
           COALESCE(b.qty,0) + COALESCE(e.qty,0) AS quantity
    FROM   (
              SELECT topping_id FROM base_after_exclusions
              UNION
              SELECT topping_id FROM extra_totals
           ) AS t
    LEFT JOIN base_after_exclusions b USING (topping_id)
    LEFT JOIN extra_totals        e USING (topping_id)
)

SELECT pt.topping_name AS name,
       totals.quantity
FROM   totals
JOIN   pizza_toppings pt
       ON pt.topping_id = totals.topping_id
ORDER BY totals.quantity DESC,
         name;