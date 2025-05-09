WITH order_core AS (                -- unique pizza‑level orders
    SELECT
        co.order_id,
        co.customer_id,
        co.pizza_id,
        pn.pizza_name,
        co.order_time
    FROM pizza_customer_orders AS co
    JOIN pizza_names          AS pn USING (pizza_id)
    GROUP BY co.order_id,
             co.customer_id,
             co.pizza_id,
             co.order_time
),
row_ids AS (                         -- choose one row_id per order (if any)
    SELECT order_id,
           MIN(row_id) AS row_id
    FROM ( SELECT order_id, row_id FROM pizza_get_extras
           UNION ALL
           SELECT order_id, row_id FROM pizza_get_exclusions )
    GROUP BY order_id
),
orders AS (                          -- dimension table of orders
    SELECT
        COALESCE(r.row_id,1) AS row_id,
        oc.order_id,
        oc.customer_id,
        oc.pizza_id,
        oc.pizza_name,
        oc.order_time
    FROM order_core oc
    LEFT JOIN row_ids r USING (order_id)
),
excl AS (                            -- excluded toppings
    SELECT order_id,
           exclusions AS topping_id
    FROM pizza_get_exclusions
),
recipe_split AS (                    -- explode standard recipe toppings
    SELECT o.order_id,
           o.pizza_id,
           CAST(value AS INTEGER) AS topping_id
    FROM orders o
    JOIN pizza_recipes pr USING (pizza_id)
    JOIN json_each('[' || pr.toppings || ']')
),
recipe_after_excl AS (               -- recipe minus exclusions
    SELECT rs.*
    FROM recipe_split rs
    LEFT JOIN excl e
           ON rs.order_id  = e.order_id
          AND rs.topping_id = e.topping_id
    WHERE e.topping_id IS NULL
),
extras_split AS (                    -- explode extras
    SELECT ge.order_id,
           o.pizza_id,
           ge.extras AS topping_id
    FROM pizza_get_extras ge
    JOIN orders o USING (order_id)
),
all_toppings AS (                    -- combine recipe + extras
    SELECT * FROM recipe_after_excl
    UNION ALL
    SELECT * FROM extras_split
),
topping_counts AS (                  -- count occurrences per topping
    SELECT order_id,
           pizza_id,
           topping_id,
           COUNT(*) AS qty
    FROM all_toppings
    GROUP BY order_id, pizza_id, topping_id
),
topping_strings AS (                 -- build display string per topping
    SELECT tc.order_id,
           tc.pizza_id,
           CASE
               WHEN qty > 1 THEN '2x ' || pt.topping_name
               ELSE               pt.topping_name
           END AS topping_str,
           pt.topping_name         -- for alphabetical ordering
    FROM topping_counts tc
    JOIN pizza_toppings pt USING (topping_id)
),
ingredients_list AS (                -- concatenate toppings alphabetically
    SELECT order_id,
           pizza_id,
           GROUP_CONCAT(topping_str, ', ') AS ingredient_list
    FROM (
        SELECT order_id,
               pizza_id,
               topping_str,
               topping_name
        FROM topping_strings
        ORDER BY order_id, pizza_id, topping_name
    )
    GROUP BY order_id, pizza_id
)
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    o.order_time,
    o.pizza_name,
    CASE WHEN o.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
    o.pizza_name || ': ' || il.ingredient_list AS final_ingredients
FROM orders           AS o
JOIN ingredients_list AS il
  ON il.order_id = o.order_id
 AND il.pizza_id = o.pizza_id
GROUP BY o.row_id,
         o.order_id,
         o.customer_id,
         o.order_time,
         o.pizza_name
ORDER BY o.row_id, o.order_id;