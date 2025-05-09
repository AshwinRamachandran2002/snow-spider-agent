WITH order_rows AS (          -- every individual pizza line we have to evaluate
    SELECT
        o.rowid                          AS row_id,      -- SQLite’s intrinsic row id
        o.order_id,
        o.customer_id,
        n.pizza_name,
        o.pizza_id                       AS orig_pizza_id,
        CASE WHEN n.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id, -- force id rule
        o.order_time
    FROM   pizza_customer_orders o
    JOIN   pizza_names           n  ON n.pizza_id = o.pizza_id
),

/* 1. standard (recipe) toppings – one copy each */
recipe_toppings AS (
    SELECT
        r.row_id,
        pt.topping_id,
        pt.topping_name,
        1 AS qty
    FROM   order_rows      r
    JOIN   pizza_recipes   pr ON pr.pizza_id = r.orig_pizza_id
    JOIN   pizza_toppings  pt ON instr(','||pr.toppings||',', ','||pt.topping_id||',')>0
),

/* 2. any extras a customer asked for (can be more than one) */
extras AS (
    SELECT
        r.row_id,
        pt.topping_id,
        pt.topping_name,
        SUM(e.extras_count) AS qty                  -- how many copies requested
    FROM   order_rows       r
    JOIN   pizza_get_extras e  ON e.order_id = r.order_id
    JOIN   pizza_toppings   pt ON pt.topping_id = e.extras
    GROUP  BY r.row_id, pt.topping_id, pt.topping_name
),

/* 3. toppings the customer wanted removed */
exclusions AS (
    SELECT
        r.row_id,
        pt.topping_id,
        pt.topping_name,
        1 AS qty                                   -- take away one copy
    FROM   order_rows            r
    JOIN   pizza_get_exclusions  x  ON x.order_id = r.order_id
    JOIN   pizza_toppings        pt ON pt.topping_id = x.exclusions
),

/* 4. put everything together: +recipe, +extras, ‑exclusions */
all_changes AS (
    SELECT row_id, topping_name,  qty              AS change_qty  FROM recipe_toppings UNION ALL
    SELECT row_id, topping_name,  qty              FROM extras         UNION ALL
    SELECT row_id, topping_name, -qty              FROM exclusions
),

tally AS (       -- final count per topping after adds/removes
    SELECT
        row_id,
        topping_name,
        SUM(change_qty) AS total_qty
    FROM   all_changes
    GROUP  BY row_id, topping_name
    HAVING SUM(change_qty) > 0                     -- keep only toppings still present
),

/* 5. build the display label, prefixing “2x” if quantity > 1 */
topping_labels AS (
    SELECT
        row_id,
        CASE WHEN total_qty > 1
             THEN '2x' || topping_name
             ELSE       topping_name
        END                       AS topping_label,
        topping_name
    FROM   tally
),

/* 6. alphabetically-ordered, comma-separated list for each pizza row */
topping_labels_sorted AS (
    SELECT row_id, topping_label
    FROM   topping_labels
    ORDER  BY row_id, topping_name
),
final_ingredients AS (
    SELECT
        row_id,
        GROUP_CONCAT(topping_label, ', ') AS ingredients
    FROM   topping_labels_sorted
    GROUP  BY row_id
)

/* 7. final answer */
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    o.pizza_name,
    o.pizza_name || ': ' || fi.ingredients AS final_ingredients
FROM   order_rows      o
JOIN   final_ingredients fi ON fi.row_id = o.row_id
ORDER  BY o.row_id;