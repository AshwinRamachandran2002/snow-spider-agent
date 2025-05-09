WITH
/* every separate line of the original orders – expose the internal
   SQLite rowid so it can be used later for grouping / ordering        */
order_rows AS (
    SELECT
        rowid  AS row_id,
        order_id,
        customer_id,
        pizza_id,
        order_time
    FROM pizza_customer_orders
),

/* turn the recipe-string into one row per standard topping            */
base_toppings AS (
    SELECT
        pr.pizza_id,
        pt.topping_id,
        pt.topping_name
    FROM pizza_recipes  pr
    JOIN pizza_toppings pt
      ON ',' || REPLACE(pr.toppings,' ','') || ','         /* add commas, remove blanks          */
         LIKE '%,' || pt.topping_id || ',%'                /* safe “contains whole token” match  */
),

/* the three “parts” that will later be summed together                */
recipe_part AS (
    SELECT
        o.row_id,
        bt.topping_id,
        bt.topping_name,
        1 AS cnt                                           -- each recipe topping counts once
    FROM order_rows o
    JOIN base_toppings bt ON bt.pizza_id = o.pizza_id
),
extras_part AS (
    SELECT
        o.row_id,
        ge.extras            AS topping_id,
        pt.topping_name,
        COALESCE(ge.extras_count,1) AS cnt                 -- how many times this extra was added
    FROM order_rows      o
    JOIN pizza_get_extras ge ON ge.order_id = o.order_id
    JOIN pizza_toppings   pt ON pt.topping_id = ge.extras
),
exclusions_part AS (
    SELECT
        o.row_id,
        gx.exclusions        AS topping_id,
        pt.topping_name,
        -1 AS cnt                                          -- remove the standard occurrence
    FROM order_rows            o
    JOIN pizza_get_exclusions gx ON gx.order_id = o.order_id
    JOIN pizza_toppings        pt ON pt.topping_id = gx.exclusions
),

/* put everything together and calculate the final quantity per topping */
all_counts AS (
    SELECT * FROM recipe_part
    UNION ALL
    SELECT * FROM extras_part
    UNION ALL
    SELECT * FROM exclusions_part
),
final_counts AS (
    SELECT
        row_id,
        topping_id,
        topping_name,
        SUM(cnt) AS final_cnt
    FROM all_counts
    GROUP BY row_id, topping_id, topping_name
    HAVING SUM(cnt) > 0                                   -- keep only toppings that remain
),

/* build the ordered, nicely-formatted ingredient list                 */
ingredients_string AS (
    SELECT
        row_id,
        GROUP_CONCAT(
            CASE
                WHEN final_cnt > 1
                     THEN printf('%dx %s', final_cnt, topping_name)
                ELSE topping_name
            END,
            ', '
        ) AS ingredient_list
    FROM (
        SELECT
            row_id,
            topping_name,
            final_cnt
        FROM final_counts
        ORDER BY row_id, topping_name                      -- ensures alphabetical order
    )
    GROUP BY row_id
)

/* final output                                                         */
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    pn.pizza_name,
    CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
    pn.pizza_name || ': ' || ingredient_list              AS final_ingredients
FROM order_rows o
JOIN pizza_names       pn  ON pn.pizza_id = o.pizza_id
LEFT JOIN ingredients_string isg ON isg.row_id = o.row_id
GROUP BY o.row_id, o.order_id, pn.pizza_name, o.order_time
ORDER BY o.row_id;