/* ------------------------------------------------------------
   Build the required “one-row-per-pizza-order” list with
   the completed ingredient set (recipe – exclusions + extras)
   ------------------------------------------------------------ */
WITH
-- 1.  Each individual pizza that was ordered
order_items AS (
    SELECT
        o.rowid                                                     AS row_id,          -- explicit row-id
        o.order_id,
        o.customer_id,
        o.pizza_id                                                  AS orig_pizza_id,   -- the id stored in source data
        CASE WHEN n.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END     AS pizza_id,        -- required mapping
        n.pizza_name,
        o.order_time
    FROM   pizza_customer_orders AS o
    JOIN   pizza_names           AS n  ON o.pizza_id = n.pizza_id
),

-- 2.  One record for every (+) or (-) change to topping counts
topping_deltas AS (
    /* +1 for every topping that is part of the standard recipe */
    SELECT  oi.row_id, t.topping_id,  1                          AS delta
    FROM    order_items  AS oi
    JOIN    pizza_recipes AS r  ON oi.orig_pizza_id = r.pizza_id
    JOIN    pizza_toppings AS t ON ','||r.toppings||',' LIKE '%,'||t.topping_id||',%'

    UNION ALL
    /* +extras_count for every extra requested */
    SELECT  oi.row_id, e.extras        AS topping_id,
            e.extras_count            AS delta
    FROM    order_items AS oi
    JOIN    pizza_get_extras AS e ON oi.order_id = e.order_id

    UNION ALL
    /* –1 for every exclusion mentioned (just 1 is enough to remove it) */
    SELECT  oi.row_id, x.exclusions    AS topping_id,
           -1                         AS delta
    FROM    order_items AS oi
    JOIN    pizza_get_exclusions AS x ON oi.order_id = x.order_id
),

-- 3.  Net quantity for every topping after all adds/removes
topping_totals AS (
    SELECT
        row_id,
        topping_id,
        CASE WHEN SUM(delta) > 0 THEN SUM(delta) ELSE 0 END AS total_cnt     -- no negative counts
    FROM   topping_deltas
    GROUP  BY row_id, topping_id
    HAVING SUM(delta) > 0                                                    -- keep toppings that remain
),

-- 4.  Convert counts into the requested text (“2x …”, “…”, etc.)
topping_strings AS (
    SELECT
        tt.row_id,
        CASE
            WHEN tt.total_cnt = 1 THEN pt.topping_name
            ELSE CAST(tt.total_cnt AS TEXT) || 'x ' || pt.topping_name
        END                                           AS ingredient_str,
        pt.topping_name                               AS sort_name          -- for alphabetical ordering
    FROM   topping_totals  AS tt
    JOIN   pizza_toppings  AS pt ON tt.topping_id = pt.topping_id
),

-- 5.  Build the final ingredient list, alphabetically ordered
final_per_pizza AS (
    SELECT
        oi.row_id,
        oi.order_id,
        oi.customer_id,
        oi.pizza_name,
        oi.order_time,
        oi.pizza_name || ': ' ||
        ( SELECT group_concat(ingredient_str, ', ')
          FROM   ( SELECT ingredient_str
                   FROM   topping_strings
                   WHERE  row_id = oi.row_id
                   ORDER  BY sort_name )                                   -- alphabetic order
        )                                            AS final_ingredients
    FROM   order_items AS oi
    GROUP  BY oi.row_id, oi.order_id, oi.customer_id, oi.pizza_name, oi.order_time
)

-- 6.  Return the requested columns in ascending row-id order
SELECT
    row_id,
    order_id,
    customer_id,
    pizza_name,
    final_ingredients
FROM   final_per_pizza
ORDER  BY row_id;