WITH RECURSIVE
    /* orders that reached the customer */
    delivered AS (
        SELECT c.order_id,
               c.pizza_id,
               COALESCE(c.exclusions,'') AS exclusions,
               COALESCE(c.extras,'')     AS extras
        FROM   pizza_customer_orders c
        JOIN   pizza_runner_orders   r
               ON r.order_id = c.order_id
        WHERE  r.cancellation IS NULL
    ),

    /* ---------- split the recipe string ---------- */
    recipe_split(order_id, rest, topping_id) AS (
        SELECT d.order_id,
               TRIM(pr.toppings) AS rest,
               CAST(
                   CASE
                     WHEN instr(TRIM(pr.toppings),',') = 0
                     THEN TRIM(pr.toppings)
                     ELSE substr(TRIM(pr.toppings),1,instr(TRIM(pr.toppings),',')-1)
                   END AS INTEGER) AS topping_id
        FROM   delivered d
        JOIN   pizza_recipes pr
               ON pr.pizza_id = d.pizza_id
        UNION ALL
        SELECT order_id,
               CASE WHEN instr(rest,',') = 0
                    THEN ''
                    ELSE substr(rest,instr(rest,',')+1)
               END,
               CAST(
                   CASE
                     WHEN instr(rest,',') = 0
                     THEN TRIM(rest)
                     ELSE substr(TRIM(rest),1,instr(TRIM(rest),',')-1)
                   END AS INTEGER)
        FROM   recipe_split
        WHERE  rest <> ''
    ),

    /* ---------- split the extras string ---------- */
    extras_split(order_id, rest, topping_id) AS (
        SELECT d.order_id,
               TRIM(d.extras) AS rest,
               CAST(
                   CASE
                     WHEN instr(TRIM(d.extras),',') = 0
                     THEN TRIM(d.extras)
                     ELSE substr(TRIM(d.extras),1,instr(TRIM(d.extras),',')-1)
                   END AS INTEGER)
        FROM   delivered d
        WHERE  d.extras <> ''
        UNION ALL
        SELECT order_id,
               CASE WHEN instr(rest,',') = 0
                    THEN ''
                    ELSE substr(rest,instr(rest,',')+1)
               END,
               CAST(
                   CASE
                     WHEN instr(rest,',') = 0
                     THEN TRIM(rest)
                     ELSE substr(TRIM(rest),1,instr(TRIM(rest),',')-1)
                   END AS INTEGER)
        FROM   extras_split
        WHERE  rest <> ''
    ),

    /* ---------- split the exclusions string ---------- */
    excl_split(order_id, rest, topping_id) AS (
        SELECT d.order_id,
               TRIM(d.exclusions) AS rest,
               CAST(
                   CASE
                     WHEN instr(TRIM(d.exclusions),',') = 0
                     THEN TRIM(d.exclusions)
                     ELSE substr(TRIM(d.exclusions),1,instr(TRIM(d.exclusions),',')-1)
                   END AS INTEGER)
        FROM   delivered d
        WHERE  d.exclusions <> ''
        UNION ALL
        SELECT order_id,
               CASE WHEN instr(rest,',') = 0
                    THEN ''
                    ELSE substr(rest,instr(rest,',')+1)
               END,
               CAST(
                   CASE
                     WHEN instr(rest,',') = 0
                     THEN TRIM(rest)
                     ELSE substr(TRIM(rest),1,instr(TRIM(rest),',')-1)
                   END AS INTEGER)
        FROM   excl_split
        WHERE  rest <> ''
    ),

    /* ---------- mark each occurrence (+1 base/extras, -1 exclusions) ---------- */
    changes AS (
        SELECT topping_id, 1  AS qty FROM recipe_split WHERE topping_id IS NOT NULL
        UNION ALL
        SELECT topping_id, 1  FROM extras_split  WHERE topping_id IS NOT NULL
        UNION ALL
        SELECT topping_id, -1 FROM excl_split    WHERE topping_id IS NOT NULL
    ),

    totals AS (
        SELECT topping_id,
               SUM(qty) AS total_quantity
        FROM   changes
        GROUP  BY topping_id
    )

SELECT t.topping_name AS ingredient,
       total_quantity
FROM   totals
JOIN   pizza_toppings t USING (topping_id)
WHERE  total_quantity > 0
ORDER  BY total_quantity DESC;