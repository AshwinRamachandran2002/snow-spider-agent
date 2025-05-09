WITH
-- every individual pizza recorded in the raw customer-order table
orders AS (
    SELECT
        pco.rowid                       AS row_id,          -- use the intrinsic rowid as the “row ID”
        pco.order_id,
        pco.customer_id,
        pco.order_time,
        pco.pizza_id,
        pn.pizza_name
    FROM pizza_customer_orders AS pco
    JOIN pizza_names            AS pn  USING (pizza_id)
),

/* --------------------------------------------------------------------
   1) explode each pizza’s standard recipe so we have
      one row per (pizza_id , topping_id)
-------------------------------------------------------------------- */
recipe_split AS (
    WITH RECURSIVE r(pizza_id, rest, topping_id) AS (
        SELECT
            pizza_id,
            TRIM(toppings) || ','              AS rest,
            NULL                               AS topping_id
        FROM pizza_recipes
        UNION ALL
        SELECT
            pizza_id,
            SUBSTR(rest, INSTR(rest, ',')+1)   AS rest,
            CAST(TRIM(SUBSTR(rest, 1, INSTR(rest, ',')-1)) AS INTEGER)
        FROM r
        WHERE rest <> ''
    )
    SELECT pizza_id, topping_id
    FROM   r
    WHERE  topping_id IS NOT NULL
),

/* --------------------------------------------------------------------
   2) collect all recipe toppings, exclusions and extras
-------------------------------------------------------------------- */
recipe_toppings AS (
    SELECT o.row_id, rs.topping_id, +1 AS delta
    FROM   orders        AS o
    JOIN   recipe_split  AS rs  ON rs.pizza_id = o.pizza_id
),
exclusion_toppings AS (
    SELECT o.row_id, CAST(e.exclusions AS INTEGER) AS topping_id, -1 AS delta
    FROM   orders                 AS o
    JOIN   pizza_get_exclusions   AS e USING (order_id)
    WHERE  e.exclusions IS NOT NULL
),
extras_toppings AS (
    SELECT o.row_id, CAST(x.extras AS INTEGER)     AS topping_id, +1 AS delta
    FROM   orders              AS o
    JOIN   pizza_get_extras    AS x USING (order_id)
    WHERE  x.extras IS NOT NULL
),

/* --------------------------------------------------------------------
   3) net effect of recipe (+1), exclusions (-1) and extras (+1)
-------------------------------------------------------------------- */
topping_counts AS (
    SELECT
        row_id,
        topping_id,
        SUM(delta) AS cnt
    FROM (
        SELECT * FROM recipe_toppings
        UNION ALL
        SELECT * FROM exclusion_toppings
        UNION ALL
        SELECT * FROM extras_toppings
    )
    GROUP BY row_id, topping_id
    HAVING SUM(delta) > 0               -- keep only toppings that survive
),

/* --------------------------------------------------------------------
   4) attach human-readable topping names and format “2x” prefixes
-------------------------------------------------------------------- */
formatted_toppings AS (
    SELECT
        tc.row_id,
        pt.topping_name,
        tc.cnt,
        CASE
            WHEN tc.cnt > 1 THEN printf('%dx %s', tc.cnt, pt.topping_name)
            ELSE pt.topping_name
        END AS ingredient
    FROM   topping_counts AS tc
    JOIN   pizza_toppings AS pt USING (topping_id)
),

/* --------------------------------------------------------------------
   5) concatenate ingredients in alphabetical order for each row_id
-------------------------------------------------------------------- */
ingredients_concat AS (
    SELECT
        row_id,
        GROUP_CONCAT(ingredient, ', ') AS ingredients_list
    FROM (
        SELECT
            row_id,
            ingredient
        FROM   formatted_toppings
        ORDER  BY row_id, topping_name         -- alphabetical inside every pizza
    )
    GROUP BY row_id
)

/* --------------------------------------------------------------------
   6) final answer
-------------------------------------------------------------------- */
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    o.pizza_name,
    o.pizza_name || ': ' || ic.ingredients_list  AS final_ingredients
FROM   orders            AS o
JOIN   ingredients_concat AS ic USING (row_id)
GROUP  BY o.row_id, o.order_id, o.pizza_name, o.order_time   -- one line per pizza order
ORDER BY o.row_id;