WITH
/* 1. Split every pizza recipe into one‑row‑per‑topping -----------------*/
recipe_toppings AS (
    SELECT
        pr.pizza_id,
        CAST(j.value AS INTEGER) AS topping_id
    FROM pizza_recipes pr,
         json_each('[' || pr.toppings || ']') j
),

/* 2. List every ordered pizza and create a deterministic row_id -------*/
orders AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY pco.order_id,
                                   pco.customer_id,
                                   pco.pizza_id)              AS row_id,
        pco.order_id,
        pco.customer_id,
        pn.pizza_name,
        CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
        pco.order_time
    FROM pizza_customer_orders pco
    JOIN pizza_names pn ON pn.pizza_id = pco.pizza_id
),

/* 3. Standard toppings (always one each) ------------------------------*/
standard AS (
    SELECT
        o.row_id,
        o.order_id,
        rt.topping_id,
        1 AS qty
    FROM orders o
    JOIN recipe_toppings rt ON rt.pizza_id = o.pizza_id
),

/* 4. Extra toppings (may have qty > 1) --------------------------------*/
extras AS (
    SELECT
        o.row_id,
        e.order_id,
        e.extras       AS topping_id,
        e.extras_count AS qty
    FROM pizza_get_extras e
    JOIN orders o ON o.order_id = e.order_id
),

/* 5. Toppings to exclude ----------------------------------------------*/
exclusions AS (
    SELECT
        o.row_id,
        ex.order_id,
        ex.exclusions AS topping_id
    FROM pizza_get_exclusions ex
    JOIN orders o ON o.order_id = ex.order_id
),

/* 6. Combine standard + extras, then drop exclusions ------------------*/
combined AS (
    SELECT row_id, order_id, topping_id, SUM(qty) AS qty
    FROM (
        SELECT * FROM standard
        UNION ALL
        SELECT * FROM extras
    )
    GROUP BY row_id, order_id, topping_id
),
final_toppings AS (
    SELECT c.*
    FROM combined c
    LEFT JOIN exclusions x
           ON  x.row_id     = c.row_id
           AND x.order_id   = c.order_id
           AND x.topping_id = c.topping_id
    WHERE x.topping_id IS NULL
)

/* 7. Build the requested result --------------------------------------*/
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    o.pizza_name,
    o.pizza_name || ': ' ||
    (
        SELECT group_concat(
                   CASE
                       WHEN t.qty > 1 THEN t.qty || 'x ' || t.topping_name
                       ELSE                  t.topping_name
                   END,
                   ', '
               )
        FROM (
            SELECT pt.topping_name,
                   ft.qty
            FROM final_toppings ft
            JOIN pizza_toppings pt
                 ON pt.topping_id = ft.topping_id
            WHERE ft.row_id = o.row_id
            ORDER BY pt.topping_name       -- alphabetical order
        ) AS t
    ) AS final_ingredients
FROM orders o
GROUP BY o.row_id, o.order_id, o.customer_id, o.pizza_name, o.order_time
ORDER BY o.row_id;