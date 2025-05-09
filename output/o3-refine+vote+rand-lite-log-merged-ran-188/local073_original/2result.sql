/* -------------------------------------------------------
   Final set of ingredients for every pizza order
   ------------------------------------------------------- */
WITH
/* ---------------------------------
   Base information about each order
-----------------------------------*/
base_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        COALESCE(e.row_id , x.row_id , o.order_id)          AS row_id,
        pn.pizza_name,
        /* enforce requested pizza‑id mapping when we need it later */
        CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS real_pizza_id
    FROM pizza_customer_orders        o
    JOIN pizza_names                  pn ON pn.pizza_id        = o.pizza_id
    LEFT JOIN pizza_get_extras         e ON e.order_id         = o.order_id
    LEFT JOIN pizza_get_exclusions     x ON x.order_id         = o.order_id
),

/* ---------------------------------
   Expand standard recipe toppings
-----------------------------------*/
standard_rows AS (
    SELECT
        b.row_id,
        b.order_id,
        b.customer_id,
        b.pizza_name,
        CAST(j.value AS INTEGER)   AS topping_id,
        1                          AS delta             -- +1 for every normal topping
    FROM base_orders      b
    JOIN pizza_recipes    r ON r.pizza_id = b.real_pizza_id
    JOIN json_each('[' || r.toppings || ']') j
),

/* ---------------------------------
   Rows coming from EXTRAS  (+)
-----------------------------------*/
extra_rows AS (
    SELECT
        COALESCE(e.row_id , o.order_id) AS row_id,
        e.order_id,
        o.customer_id,
        pn.pizza_name,
        CAST(e.extras AS INTEGER)       AS topping_id,
        e.extras_count                  AS delta         -- add extras_count times
    FROM pizza_get_extras  e
    JOIN pizza_customer_orders  o ON o.order_id = e.order_id
    JOIN pizza_names        pn ON pn.pizza_id = o.pizza_id
),

/* ---------------------------------
   Rows coming from EXCLUSIONS  (–)
-----------------------------------*/
exclusion_rows AS (
    SELECT
        COALESCE(x.row_id , o.order_id) AS row_id,
        x.order_id,
        o.customer_id,
        pn.pizza_name,
        CAST(x.exclusions AS INTEGER)   AS topping_id,
       -x.total_exclusions              AS delta         -- subtract exclusions
    FROM pizza_get_exclusions x
    JOIN pizza_customer_orders  o ON o.order_id = x.order_id
    JOIN pizza_names        pn ON pn.pizza_id = o.pizza_id
),

/* ---------------------------------
   Combine every (+/–) row together
-----------------------------------*/
all_rows AS (
    SELECT * FROM standard_rows
    UNION ALL
    SELECT * FROM extra_rows
    UNION ALL
    SELECT * FROM exclusion_rows
),

/* ---------------------------------
   Net quantity of every topping
-----------------------------------*/
topping_totals AS (
    SELECT
        row_id,
        order_id,
        customer_id,
        pizza_name,
        topping_id,
        SUM(delta) AS final_cnt
    FROM all_rows
    GROUP BY row_id, order_id, customer_id, pizza_name, topping_id
    HAVING SUM(delta) > 0                -- keep only toppings that remain
),

/* ---------------------------------
   Make readable topping strings
-----------------------------------*/
topping_strings AS (
    SELECT
        tt.row_id,
        tt.order_id,
        tt.customer_id,
        tt.pizza_name,
        CASE
            WHEN tt.final_cnt > 1 THEN tt.final_cnt || 'x ' || pt.topping_name
            ELSE pt.topping_name
        END                AS topping_display,
        pt.topping_name    AS alpha_order         -- helper for alphabetical sort
    FROM topping_totals tt
    JOIN pizza_toppings pt ON pt.topping_id = tt.topping_id
),

/* ---------------------------------
   Alphabetically order toppings
-----------------------------------*/
ordered_toppings AS (
    SELECT *
    FROM topping_strings
    ORDER BY row_id, order_id, alpha_order
),

/* ---------------------------------
   Concatenate toppings per order
-----------------------------------*/
assembled AS (
    SELECT
        row_id,
        order_id,
        customer_id,
        pizza_name,
        GROUP_CONCAT(topping_display, ', ') AS toppings_list
    FROM ordered_toppings
    GROUP BY row_id, order_id, customer_id, pizza_name
)

/* ---------------------------------
   Final required output
-----------------------------------*/
SELECT
    row_id,
    order_id,
    customer_id,
    pizza_name,
    pizza_name || ': ' || toppings_list  AS final_ingredients
FROM assembled
ORDER BY row_id;