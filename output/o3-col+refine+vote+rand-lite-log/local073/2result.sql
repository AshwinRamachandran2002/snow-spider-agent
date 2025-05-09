WITH orders AS (           -- 1) one row per stored pizza order
    SELECT
        rowid                                            AS row_id,
        order_id,
        customer_id,
        /* force-map: Meatlovers = 1, everything else = 2 */
        CASE WHEN pizza_id = 1 THEN 1 ELSE 2 END         AS pizza_id,
        exclusions,
        extras
    FROM pizza_customer_orders
),
recipe AS (               -- 2) explode each pizza’s default toppings
    SELECT
        pr.pizza_id,
        TRIM(j.value)                                     AS topping_id
    FROM pizza_recipes AS pr,
         json_each('[' || pr.toppings || ']') AS j
),
order_excl AS (           -- 3) explode per-order exclusions
    SELECT
        o.row_id,
        TRIM(j.value)                                     AS topping_id
    FROM orders AS o,
         json_each('[' || IFNULL(o.exclusions,'') || ']') AS j
    WHERE o.exclusions IS NOT NULL
      AND o.exclusions <> ''
),
order_extra AS (          -- 4) explode per-order extras
    SELECT
        o.row_id,
        TRIM(j.value)                                     AS topping_id
    FROM orders AS o,
         json_each('[' || IFNULL(o.extras,'') || ']')     AS j
    WHERE o.extras IS NOT NULL
      AND o.extras <> ''
),
base AS (                 -- 5) recipe after removing exclusions
    SELECT
        o.row_id,
        r.topping_id
    FROM orders  AS o
    JOIN recipe  AS r USING (pizza_id)
    WHERE r.topping_id NOT IN (
          SELECT topping_id
          FROM   order_excl
          WHERE  row_id = o.row_id
    )
),
combined AS (             -- 6) add extras (duplicates allowed)
    SELECT row_id, topping_id FROM base
    UNION ALL
    SELECT row_id, topping_id FROM order_extra
),
counted AS (              -- 7) final count of each topping per order
    SELECT
        row_id,
        topping_id,
        COUNT(*)                              AS cnt
    FROM combined
    GROUP BY row_id, topping_id
),
named AS (                -- 8) convert id → name & apply “2x ” prefix
    SELECT
        c.row_id,
        CASE WHEN c.cnt > 1
             THEN printf('%dx %s', c.cnt, pt.topping_name)
             ELSE               pt.topping_name
        END                                  AS ingredient
    FROM counted        AS c
    JOIN pizza_toppings AS pt
      ON pt.topping_id = c.topping_id
),
ingredient_list AS (      -- 9) alphabetical, comma-separated list
    SELECT
        row_id,
        GROUP_CONCAT(ingredient, ', ')       AS ingredients
    FROM (
        SELECT row_id, ingredient
        FROM   named
        ORDER  BY ingredient                 -- alphabetise
    )
    GROUP BY row_id
)
-- 10) assemble and return final answer
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    pn.pizza_name,
    pn.pizza_name || ': ' || il.ingredients  AS final_ingredients
FROM orders           AS o
JOIN pizza_names      AS pn USING (pizza_id)
JOIN ingredient_list  AS il USING (row_id)
ORDER BY o.row_id;