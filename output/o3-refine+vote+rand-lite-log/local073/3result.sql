WITH RECURSIVE
/* -------------------------------------------------
   base information for every order
--------------------------------------------------*/
base_orders AS (
    SELECT
        o.rowid AS row_id,                 -- sqlite internal rowid
        o.order_id,
        o.customer_id,
        /* force pizza_id = 1 for Meatlovers, 2 for every other pizza */
        CASE WHEN p.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
        p.pizza_name,
        o.order_time
    FROM pizza_clean_customer_orders AS o
    JOIN pizza_names                AS p
      ON p.pizza_id = o.pizza_id
),
/* -------------------------------------------------
   explode each recipe into one‑row‑per‑topping
--------------------------------------------------*/
recipe_split(pizza_id, piece, rest) AS (
    /* first slice from every recipe row */
    SELECT
        pizza_id,
        trim(substr(toppings, 1, instr(toppings||',', ',') - 1)),
        substr(toppings||',', instr(toppings||',', ',') + 1)
    FROM pizza_recipes
    UNION ALL
    /* keep chopping until nothing left */
    SELECT
        pizza_id,
        trim(substr(rest, 1, instr(rest, ',') - 1)),
        substr(rest, instr(rest, ',') + 1)
    FROM recipe_split
    WHERE rest <> ''
),
recipe_toppings AS (
    SELECT
        pizza_id,
        CAST(piece AS INTEGER) AS topping_id,
        1 AS delta                       -- every recipe topping counts +1
    FROM recipe_split
    WHERE piece <> ''
),
/* -------------------------------------------------
   extras (+) and exclusions (‑)
--------------------------------------------------*/
extras AS (
    SELECT
        order_id,
        extras AS topping_id,
        SUM(extras_count) AS delta       -- positive
    FROM pizza_get_extras
    GROUP BY order_id, extras
),
exclusions AS (
    SELECT
        order_id,
        exclusions AS topping_id,
        -SUM(total_exclusions) AS delta  -- negative
    FROM pizza_get_exclusions
    GROUP BY order_id, exclusions
),
/* -------------------------------------------------
   collect every “event” (recipe, extras, exclusions)
--------------------------------------------------*/
events AS (
    /* recipe defaults */
    SELECT
        b.row_id,
        b.order_id,
        r.topping_id,
        r.delta
    FROM base_orders      AS b
    JOIN recipe_toppings  AS r
      ON r.pizza_id = b.pizza_id

    UNION ALL
    /* extras */
    SELECT
        b.row_id,
        b.order_id,
        e.topping_id,
        e.delta
    FROM base_orders  AS b
    JOIN extras       AS e
      ON e.order_id = b.order_id

    UNION ALL
    /* exclusions */
    SELECT
        b.row_id,
        b.order_id,
        x.topping_id,
        x.delta
    FROM base_orders  AS b
    JOIN exclusions   AS x
      ON x.order_id = b.order_id
),
/* -------------------------------------------------
   sum the deltas per topping; keep only positive totals
--------------------------------------------------*/
final_counts AS (
    SELECT
        row_id,
        order_id,
        topping_id,
        SUM(delta) AS final_cnt
    FROM events
    GROUP BY row_id, order_id, topping_id
    HAVING SUM(delta) > 0
),
/* -------------------------------------------------
   translate topping_id → name and apply the “2x ” rule
--------------------------------------------------*/
named_toppings AS (
    SELECT
        fc.row_id,
        fc.order_id,
        CASE
            WHEN fc.final_cnt > 1 THEN '2x ' || t.topping_name
            ELSE                        t.topping_name
        END AS topping_name
    FROM final_counts   AS fc
    JOIN pizza_toppings AS t
      ON t.topping_id = fc.topping_id
),
/* -------------------------------------------------
   alphabetical list per order
--------------------------------------------------*/
ordered_named_toppings AS (
    SELECT
        row_id,
        order_id,
        topping_name
    FROM named_toppings
    ORDER BY topping_name
),
topping_strings AS (
    SELECT
        row_id,
        order_id,
        GROUP_CONCAT(topping_name, ', ') AS toppings_list
    FROM ordered_named_toppings
    GROUP BY row_id, order_id
)
/* -------------------------------------------------
   final result
--------------------------------------------------*/
SELECT
    b.row_id,
    b.order_id,
    b.customer_id,
    b.pizza_name,
    b.pizza_name || ': ' || COALESCE(t.toppings_list, '') AS ingredients
FROM base_orders      AS b
LEFT JOIN topping_strings AS t
       ON t.row_id  = b.row_id
      AND t.order_id = b.order_id
GROUP BY
    b.row_id,
    b.order_id,
    b.customer_id,
    b.pizza_name,
    b.order_time
ORDER BY
    b.row_id;