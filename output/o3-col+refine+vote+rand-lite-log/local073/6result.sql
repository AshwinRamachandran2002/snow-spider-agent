WITH base_orders AS (          -- every pizza row together with its rowid
    SELECT
        o.rowid        AS row_id,
        o.order_id,
        o.customer_id,
        o.order_time,
        pn.pizza_name,
        o.pizza_id                  -- 1 = Meatlovers, 2 = Vegetarian (already satisfied)
    FROM   pizza_customer_orders o
    JOIN   pizza_names         pn ON pn.pizza_id = o.pizza_id
),

/* ---------------------------------------------------------------
   1. Standard recipe toppings for each pizza row
-----------------------------------------------------------------*/
std AS (
    SELECT
        b.row_id,
        b.order_id,
        CAST(j.value AS INTEGER) AS topping_id,
        1 AS cnt                       -- each recipe topping counts once
    FROM   base_orders b
    JOIN   pizza_recipes r   ON r.pizza_id = b.pizza_id
    JOIN   json_each('[' || r.toppings || ']') j
),

/* ---------------------------------------------------------------
   2. Toppings to EXCLUDE (removed once)
-----------------------------------------------------------------*/
excl AS (
    SELECT
        order_id,
        exclusions AS topping_id
    FROM   pizza_get_exclusions
),

/* ---------------------------------------------------------------
   3. Toppings to add as EXTRAS (may be repeated)
-----------------------------------------------------------------*/
extras AS (
    SELECT
        order_id,
        extras        AS topping_id,
        extras_count  AS cnt
    FROM   pizza_get_extras
),

/* ---------------------------------------------------------------
   4. Keep recipe toppings that were NOT excluded
-----------------------------------------------------------------*/
std_no_excl AS (
    SELECT
        s.row_id,
        s.order_id,
        s.topping_id,
        s.cnt
    FROM   std s
    LEFT JOIN excl x
           ON x.order_id   = s.order_id
          AND x.topping_id = s.topping_id
    WHERE  x.topping_id IS NULL
),

/* ---------------------------------------------------------------
   5. Union remaining recipe toppings with extras
-----------------------------------------------------------------*/
all_toppings AS (
    SELECT row_id, order_id, topping_id, cnt
    FROM   std_no_excl
    UNION ALL
    SELECT NULL, order_id, topping_id, cnt
    FROM   extras
),

/* ---------------------------------------------------------------
   6. Total count of each topping per ORDER (to see if it’s 2x)
-----------------------------------------------------------------*/
totals AS (
    SELECT
        order_id,
        topping_id,
        SUM(cnt) AS total_cnt
    FROM   all_toppings
    GROUP BY order_id, topping_id
),

/* ---------------------------------------------------------------
   7. Convert topping_id → readable string, add “2x ” if repeated
-----------------------------------------------------------------*/
named AS (
    SELECT
        t.order_id,
        CASE
            WHEN t.total_cnt > 1 THEN '2x ' || p.topping_name
            ELSE                       p.topping_name
        END AS topping_str
    FROM   totals t
    JOIN   pizza_toppings p ON p.topping_id = t.topping_id
),

/* ---------------------------------------------------------------
   8. Alphabetically sort toppings and concatenate with commas
-----------------------------------------------------------------*/
alphabetic AS (
    SELECT
        order_id,
        GROUP_CONCAT(topping_str, ', ') AS toppings_list
    FROM (
        SELECT order_id, topping_str
        FROM   named
        ORDER  BY topping_str          -- alphabetical order inside each order
    )
    GROUP BY order_id
)

/* ---------------------------------------------------------------
   9. Final answer
-----------------------------------------------------------------*/
SELECT
    b.row_id,
    b.order_id,
    b.customer_id,
    b.pizza_name,
    b.pizza_name || ': ' || a.toppings_list AS final_ingredients
FROM   base_orders b
JOIN   alphabetic  a ON a.order_id = b.order_id
GROUP BY
    b.row_id,                -- row ID
    b.order_id,              -- order ID
    b.customer_id,
    b.pizza_name,
    b.order_time             -- ensures each pizza row appears once
ORDER BY b.row_id;