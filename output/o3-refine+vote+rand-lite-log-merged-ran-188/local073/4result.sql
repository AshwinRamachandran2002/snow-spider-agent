WITH
/* ---- 1. every individual pizza line in the raw customer file ---- */
base_orders AS (
    SELECT
        rowid                  AS row_id,   -- unique row within pizza_customer_orders
        order_id,
        customer_id,
        pizza_id
    FROM pizza_customer_orders
),

/* ---- 2. standard toppings coming from the recipe (count = 1) ---- */
standard AS (
    SELECT
        bo.row_id,
        pt.topping_id,
        pt.topping_name,
        1                       AS qty
    FROM base_orders      bo
    JOIN pizza_recipes    pr  ON pr.pizza_id = bo.pizza_id
    JOIN pizza_toppings   pt  ON ','||pr.toppings||',' LIKE '%,'||pt.topping_id||',%'
),

/* ---- 3. extras requested by the customer (use extras_count) ---- */
extras AS (
    SELECT
        bo.row_id,
        ge.extras              AS topping_id,
        pt.topping_name,
        ge.extras_count        AS qty
    FROM base_orders        bo
    JOIN pizza_get_extras   ge  ON ge.order_id = bo.order_id
    JOIN pizza_toppings     pt  ON pt.topping_id = ge.extras
),

/* ---- 4. exclusions requested by the customer (used to subtract) ---- */
exclusions AS (
    SELECT
        bo.row_id,
        gx.exclusions          AS topping_id,
        gx.total_exclusions    AS qty
    FROM base_orders           bo
    JOIN pizza_get_exclusions  gx ON gx.order_id = bo.order_id
),

/* ---- 5. union of all adds (standard + extras) --------------------- */
adds AS (
    SELECT * FROM standard
    UNION ALL
    SELECT * FROM extras
),

/* ---- 6. net quantity for each topping after removing exclusions --- */
net_toppings AS (
    SELECT
        a.row_id,
        a.topping_name,
        SUM(a.qty) - COALESCE((
              SELECT SUM(e.qty)
              FROM exclusions e
              WHERE e.row_id = a.row_id
                AND e.topping_id = a.topping_id
        ),0)                   AS qty
    FROM adds a
    GROUP BY a.row_id, a.topping_name
    HAVING qty > 0
),

/* ---- 7. build alphabetically-sorted ingredient string per pizza --- */
final_strings AS (
    SELECT
        row_id,
        GROUP_CONCAT(
            CASE
                WHEN qty > 1 THEN qty || 'x' || topping_name
                ELSE topping_name
            END,
            ', '
        ) AS ingredients
    FROM (
        SELECT
            nt.row_id,
            nt.topping_name,
            nt.qty
        FROM net_toppings nt
        ORDER BY nt.row_id, nt.topping_name           -- ensures alpha order inside each row_id
    )
    GROUP BY row_id
)

/* ---- 8. assemble the required output -------------------------------- */
SELECT
    bo.row_id,
    bo.order_id,
    bo.customer_id,
    pn.pizza_name,
    pn.pizza_name || ': ' || fs.ingredients      AS final_ingredients
FROM base_orders  bo
JOIN pizza_names  pn ON pn.pizza_id = bo.pizza_id   -- Meatlovers → 1, others → 2 already satisfied
LEFT JOIN final_strings fs ON fs.row_id = bo.row_id
GROUP BY bo.row_id, bo.order_id, bo.customer_id, pn.pizza_name
ORDER BY bo.row_id;