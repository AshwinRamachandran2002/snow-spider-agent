WITH delivered_orders AS (                     -- orders that were actually delivered
    SELECT  co.order_id,
            co.pizza_id
    FROM    pizza_customer_orders  AS co
    JOIN    pizza_runner_orders    AS ro
           ON co.order_id = ro.order_id
    WHERE   ro.cancellation IS NULL
),
base_toppings AS (                             -- toppings from the original recipe
    SELECT  d.order_id,
            CAST(json_extract(j.value,'$') AS INTEGER) AS topping_id
    FROM    delivered_orders d
    JOIN    pizza_recipes  pr  ON d.pizza_id = pr.pizza_id,
          json_each('[' || pr.toppings || ']') AS j
),
exclusions AS (                                -- toppings customers removed
    SELECT  order_id,
            exclusions AS topping_id
    FROM    pizza_get_exclusions
),
extras AS (                                    -- toppings customers added
    SELECT  order_id,
            extras AS topping_id,
            COALESCE(extras_count,1) AS qty
    FROM    pizza_get_extras
),
base_after_excl AS (                           -- base toppings after removals
    SELECT  b.order_id,
            b.topping_id
    FROM    base_toppings b
    LEFT JOIN exclusions e
           ON b.order_id   = e.order_id
          AND b.topping_id = e.topping_id
    WHERE   e.order_id IS NULL
),
all_toppings AS (                              -- final list of toppings with quantities
    SELECT  topping_id, 1 AS qty
    FROM    base_after_excl
    UNION ALL
    SELECT  topping_id, qty
    FROM    extras
    WHERE   order_id IN (SELECT order_id FROM delivered_orders)
)
SELECT  pt.topping_name AS ingredient,
        SUM(at.qty)     AS total_quantity
FROM    all_toppings at
JOIN    pizza_toppings pt
       ON at.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY total_quantity DESC, ingredient;