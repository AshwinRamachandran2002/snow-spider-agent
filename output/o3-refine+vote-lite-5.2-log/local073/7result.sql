WITH
/* -----------------------------------------------------------
1.  Basic order details and required pizza name/id
----------------------------------------------------------- */
base_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_time,
        CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
        pn.pizza_name
    FROM pizza_clean_customer_orders AS o
    JOIN pizza_names AS pn
      ON pn.pizza_id = o.pizza_id
),

/* -----------------------------------------------------------
2.  Turn each recipe’s topping list into one row per topping
----------------------------------------------------------- */
recipe_toppings AS (
    WITH RECURSIVE split(order_id, topping_id, rest) AS (
        /* seed rows */
        SELECT
            bo.order_id,
            CAST(
                TRIM(SUBSTR(pr.toppings,
                            1,
                            INSTR(pr.toppings || ',', ',') - 1)) AS INTEGER
            )                                                          AS topping_id,
            SUBSTR(pr.toppings || ',',
                   INSTR(pr.toppings || ',', ',') + 1)                 AS rest
        FROM base_orders bo
        JOIN pizza_recipes pr
          ON pr.pizza_id = bo.pizza_id

        UNION ALL

        /* keep splitting until nothing left */
        SELECT
            order_id,
            CAST(
                TRIM(SUBSTR(rest,
                            1,
                            INSTR(rest, ',') - 1)) AS INTEGER
            )                                                          AS topping_id,
            SUBSTR(rest, INSTR(rest, ',') + 1)                         AS rest
        FROM split
        WHERE rest <> ''
    )
    SELECT
        order_id,
        topping_id,
        1 AS cnt                       -- each recipe topping appears once
    FROM split
),

/* -----------------------------------------------------------
3.  Extras and exclusions chosen by the customer
----------------------------------------------------------- */
extra_toppings AS (
    SELECT
        order_id,
        extras        AS topping_id,
        extras_count  AS cnt
    FROM pizza_get_extras
),
exclusion_toppings AS (
    SELECT
        order_id,
        exclusions AS topping_id
    FROM pizza_get_exclusions
),

/* -----------------------------------------------------------
4.  Apply exclusions then add extras
----------------------------------------------------------- */
recipe_after_excl AS (
    SELECT
        r.order_id,
        r.topping_id,
        r.cnt
    FROM recipe_toppings r
    LEFT JOIN exclusion_toppings e
           ON e.order_id = r.order_id
          AND e.topping_id = r.topping_id
    WHERE e.topping_id IS NULL                -- drop excluded items
),
all_toppings AS (
    SELECT
        order_id,
        topping_id,
        SUM(cnt) AS total_cnt
    FROM (
        SELECT * FROM recipe_after_excl
        UNION ALL
        SELECT * FROM extra_toppings
    )
    GROUP BY order_id, topping_id
),

/* -----------------------------------------------------------
5.  Build ingredient text, taking duplicates into account
----------------------------------------------------------- */
ingredient_strings AS (
    SELECT
        a.order_id,
        t.topping_name,
        CASE
            WHEN a.total_cnt > 1 THEN '2x ' || t.topping_name
            ELSE                        t.topping_name
        END AS ingredient_text
    FROM all_toppings a
    JOIN pizza_toppings t
      ON t.topping_id = a.topping_id
),

/* -----------------------------------------------------------
6.  Alphabetically concatenate ingredients for each order
----------------------------------------------------------- */
ingredients_per_order AS (
    SELECT
        order_id,
        GROUP_CONCAT(ingredient_text, ', ') AS ingredients_list
    FROM (
        SELECT
            order_id,
            ingredient_text
        FROM ingredient_strings
        ORDER BY order_id, topping_name      -- alpha order inside each order
    )
    GROUP BY order_id
),

/* -----------------------------------------------------------
7.  Final output with sequential row_id
----------------------------------------------------------- */
final_output AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY bo.order_id) AS row_id,
        bo.order_id,
        bo.customer_id,
        bo.pizza_name,
        bo.pizza_name || ': ' ||
        COALESCE(ip.ingredients_list, '')        AS final_ingredients
    FROM base_orders bo
    LEFT JOIN ingredients_per_order ip
           ON ip.order_id = bo.order_id
)
SELECT
    row_id,
    order_id,
    customer_id,
    pizza_name,
    final_ingredients
FROM final_output
ORDER BY row_id;