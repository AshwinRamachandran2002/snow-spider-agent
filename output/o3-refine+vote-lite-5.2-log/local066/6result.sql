WITH RECURSIVE
/* ------------------------------------------------------------------
   1. Orders that were actually delivered (runner did not cancel)
-------------------------------------------------------------------*/
delivered_orders AS (
    SELECT o.order_id,
           o.pizza_id,
           o.exclusions,
           o.extras
    FROM   pizza_customer_orders o
    JOIN   pizza_runner_orders   r USING (order_id)
    WHERE  r.cancellation IS NULL
),

/* ------------------------------------------------------------------
   2. Break the “standard” recipe toppings (pizza_recipes.toppings)
-------------------------------------------------------------------*/
base_split(order_id, rest, topping_id) AS (
    /* anchor – start with full comma‑terminated string */
    SELECT d.order_id,
           TRIM(REPLACE(pr.toppings,' ','')) || ','  AS rest,
           NULL                                       AS topping_id
    FROM   delivered_orders d
    JOIN   pizza_recipes pr USING (pizza_id)

    UNION ALL
    /* recursive step – peel off the first id, continue with the tail */
    SELECT order_id,
           SUBSTR(rest, INSTR(rest, ',')+1),
           CAST(SUBSTR(rest, 1, INSTR(rest, ',')-1) AS INTEGER)
    FROM   base_split
    WHERE  rest <> ''
),
base_toppings AS (
    SELECT order_id, topping_id
    FROM   base_split
    WHERE  topping_id IS NOT NULL
),

/* ------------------------------------------------------------------
   3. Break exclusions
-------------------------------------------------------------------*/
excl_split(order_id, rest, topping_id) AS (
    SELECT order_id,
           CASE WHEN exclusions IS NULL OR exclusions=''
                THEN '' ELSE TRIM(REPLACE(exclusions,' ','')) || ',' END,
           NULL
    FROM   delivered_orders

    UNION ALL
    SELECT order_id,
           SUBSTR(rest, INSTR(rest, ',')+1),
           CAST(SUBSTR(rest, 1, INSTR(rest, ',')-1) AS INTEGER)
    FROM   excl_split
    WHERE  rest <> ''
),
exclusions AS (
    SELECT order_id, topping_id
    FROM   excl_split
    WHERE  topping_id IS NOT NULL
),

/* ------------------------------------------------------------------
   4. Break extras (each counts as an extra serve)
-------------------------------------------------------------------*/
extra_split(order_id, rest, topping_id) AS (
    SELECT order_id,
           CASE WHEN extras IS NULL OR extras=''
                THEN '' ELSE TRIM(REPLACE(extras,' ','')) || ',' END,
           NULL
    FROM   delivered_orders

    UNION ALL
    SELECT order_id,
           SUBSTR(rest, INSTR(rest, ',')+1),
           CAST(SUBSTR(rest, 1, INSTR(rest, ',')-1) AS INTEGER)
    FROM   extra_split
    WHERE  rest <> ''
),
extras AS (
    SELECT order_id, topping_id
    FROM   extra_split
    WHERE  topping_id IS NOT NULL
),

/* ------------------------------------------------------------------
   5. Keep recipe toppings that were NOT excluded
-------------------------------------------------------------------*/
final_base AS (
    SELECT b.order_id,
           b.topping_id
    FROM   base_toppings b
    LEFT  JOIN exclusions e
           ON  e.order_id   = b.order_id
           AND e.topping_id = b.topping_id
    WHERE  e.topping_id IS NULL
),

/* ------------------------------------------------------------------
   6. Everything that finally appears on the pizzas
-------------------------------------------------------------------*/
all_toppings AS (
    SELECT topping_id FROM final_base
    UNION ALL
    SELECT topping_id FROM extras
)

/* ------------------------------------------------------------------
   7. Aggregate ingredient usage
-------------------------------------------------------------------*/
SELECT pt.topping_name  AS ingredient,
       COUNT(*)         AS quantity
FROM   all_toppings at
JOIN   pizza_toppings pt ON pt.topping_id = at.topping_id
GROUP  BY pt.topping_name
ORDER  BY quantity DESC,
        pt.topping_name;