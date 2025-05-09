WITH delivered_orders AS (           -- only the orders that were actually delivered
    SELECT cco.order_id ,
           cco.pizza_id
    FROM   pizza_clean_customer_orders  AS cco
    JOIN   pizza_clean_runner_orders    AS cro
           ON cro.order_id = cco.order_id
    WHERE  cro.cancellation IS NULL
),

/* --------  split the recipe string (e.g. '1, 2, 3') into one row per topping  -------- */
recipe_strings AS (
    SELECT  do.order_id,
            TRIM(pr.toppings)  AS toppings
    FROM    delivered_orders  AS do
    JOIN    pizza_recipes     AS pr
           ON pr.pizza_id = do.pizza_id
),
split_base AS (                      -- recursive splitter
    SELECT
        order_id,
        CAST(TRIM( substr(toppings,1,
                          CASE WHEN instr(toppings,',')=0 
                               THEN length(toppings) 
                               ELSE instr(toppings,',')-1 END) ) AS INTEGER)  AS topping_id,
        CASE WHEN instr(toppings,',')=0 
             THEN '' 
             ELSE substr(toppings, instr(toppings,',')+1) END               AS rest
    FROM  recipe_strings
    UNION ALL
    SELECT
        order_id,
        CAST(TRIM( substr(rest,1,
                          CASE WHEN instr(rest,',')=0 
                               THEN length(rest) 
                               ELSE instr(rest,',')-1 END) ) AS INTEGER),
        CASE WHEN instr(rest,',')=0 
             THEN '' 
             ELSE substr(rest, instr(rest,',')+1) END
    FROM  split_base
    WHERE rest <> ''
),
base_toppings AS (                    -- one unit of each recipe topping
    SELECT order_id,
           topping_id,
           1 AS qty
    FROM   split_base
),

/* --------  toppings the customer asked to remove  -------- */
exclusions AS (
    SELECT  pge.order_id,
            pge.exclusions AS topping_id
    FROM    pizza_get_exclusions AS pge
    WHERE   pge.order_id IN (SELECT order_id FROM delivered_orders)
),

/* --------  recipe toppings after taking out the exclusions  -------- */
filtered_base AS (
    SELECT  b.order_id,
            b.topping_id,
            b.qty
    FROM    base_toppings AS b
    LEFT  JOIN exclusions  AS e
           ON  e.order_id   = b.order_id
           AND e.topping_id = b.topping_id
    WHERE   e.topping_id IS NULL
),

/* --------  any extra toppings the customer added (can be >1)  -------- */
extras AS (
    SELECT  pge.order_id,
            pge.extras       AS topping_id,
            COALESCE(pge.extras_count,1) AS qty
    FROM    pizza_get_extras AS pge
    WHERE   pge.order_id IN (SELECT order_id FROM delivered_orders)
),

/* --------  gather every topping that finally went on a pizza  -------- */
all_toppings AS (
    SELECT topping_id, qty FROM filtered_base
    UNION ALL
    SELECT topping_id, qty FROM extras
),

/* --------  total quantity of each topping across all delivered pizzas  -------- */
totals AS (
    SELECT  topping_id,
            SUM(qty) AS total_qty
    FROM    all_toppings
    GROUP  BY topping_id
)

SELECT  pt.topping_name  AS ingredient,
        totals.total_qty AS quantity
FROM    totals
JOIN    pizza_toppings AS pt
       ON pt.topping_id = totals.topping_id
ORDER BY pt.topping_name;