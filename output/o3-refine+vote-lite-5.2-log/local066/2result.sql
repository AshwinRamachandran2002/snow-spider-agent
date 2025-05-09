WITH
/* 1. Orders that were actually delivered (i.e. not cancelled) */
delivered_orders AS (
    SELECT order_id
    FROM pizza_clean_runner_orders
    WHERE cancellation IS NULL
),

/* 2. Their corresponding pizza choices                                */
customer_pizzas AS (
    SELECT c.order_id,
           c.pizza_id
    FROM   pizza_clean_customer_orders c
    JOIN   delivered_orders d USING (order_id)
),

/* 3. Recipe strings for every delivered order                          */
recipe_strings AS (
    SELECT cp.order_id,
           pr.toppings        AS topping_str         -- comma‑separated ids
    FROM   customer_pizzas cp
    JOIN   pizza_recipes  pr USING (pizza_id)
),

/* 4. Split the comma‑separated strings into one row per topping id      */
split(order_id, str, topping_id) AS (
    /* seed rows                                                         */
    SELECT order_id,
           trim(topping_str),          -- working remainder
           NULL                        -- placeholder
    FROM   recipe_strings
    UNION ALL
    /* recursive part extracts first id, keeps the rest                  */
    SELECT order_id,
           ltrim(
                CASE WHEN instr(str, ',')=0
                     THEN ''
                     ELSE substr(str, instr(str,',')+1)
                END
           ),
           CAST(
                trim(
                     CASE WHEN instr(str, ',')=0
                          THEN str
                          ELSE substr(str, 1, instr(str,',')-1)
                     END
                ) AS INTEGER
           )                            AS topping_id
    FROM   split
    WHERE  str <> ''
),

/* 5. Base toppings actually present after removing exclusions           */
base_toppings AS (
    SELECT s.order_id,
           s.topping_id
    FROM   split s
    WHERE  s.topping_id IS NOT NULL
),
base_counts AS (
    SELECT bt.topping_id,
           COUNT(*) AS qty
    FROM   base_toppings bt
    LEFT   JOIN pizza_get_exclusions ex
           ON  bt.order_id  = ex.order_id
           AND bt.topping_id = ex.exclusions      -- remove excluded items
    WHERE  ex.exclusions IS NULL
    GROUP  BY bt.topping_id
),

/* 6. Extra toppings requested                                           */
extra_counts AS (
    SELECT ge.extras        AS topping_id,
           SUM(COALESCE(ge.extras_count,1)) AS qty
    FROM   pizza_get_extras ge
    JOIN   delivered_orders d USING (order_id)
    GROUP  BY ge.extras
),

/* 7. Combine base and extra quantities                                  */
total_counts AS (
    SELECT t.topping_id,
           COALESCE(b.qty,0) + COALESCE(e.qty,0) AS total_qty
    FROM (
        SELECT topping_id FROM base_counts
        UNION
        SELECT topping_id FROM extra_counts
    ) t
    LEFT JOIN base_counts  b USING (topping_id)
    LEFT JOIN extra_counts e USING (topping_id)
)

/* 8. Return ingredient name and total quantity                          */
SELECT pt.topping_name   AS name,
       total_qty         AS quantity
FROM   total_counts tc
JOIN   pizza_toppings pt ON pt.topping_id = tc.topping_id
ORDER  BY quantity DESC, name;