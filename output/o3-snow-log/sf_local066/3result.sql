/* 1) identify pizzas that were actually delivered (no cancellation)            */
/* 2) turn the base recipe toppings, customer exclusions and extras into rows   */
/* 3) subtract exclusions from the base, then add extras                        */
/* 4) aggregate how many times every topping is finally used                    */
WITH delivered_orders AS (   -- only pizzas that reached the customer
    SELECT  co."order_id",
            co."pizza_id",
            co."exclusions",
            co."extras"
    FROM    MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS  co
    JOIN    MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS    ro
            ON co."order_id" = ro."order_id"
    WHERE   COALESCE(ro."cancellation",'') = ''
),
base_toppings AS (           -- one row per base-recipe topping
    SELECT  d."order_id",
            TRIM(t.value)::NUMBER AS topping_id
    FROM    delivered_orders d
    JOIN    MODERN_DATA.MODERN_DATA.PIZZA_RECIPES r
            ON d."pizza_id" = r."pizza_id",
            LATERAL FLATTEN( input => SPLIT(r."toppings",',') ) t
),
exclusions AS (              -- one row per excluded topping
    SELECT  d."order_id",
            TRIM(e.value)::NUMBER AS topping_id
    FROM    delivered_orders d,
            LATERAL FLATTEN( input => SPLIT(d."exclusions",',') ) e
    WHERE   TRIM(d."exclusions") IS NOT NULL
            AND TRIM(d."exclusions") <> ''
),
extras AS (                  -- one row per extra topping
    SELECT  d."order_id",
            TRIM(x.value)::NUMBER AS topping_id
    FROM    delivered_orders d,
            LATERAL FLATTEN( input => SPLIT(d."extras",',') ) x
    WHERE   TRIM(d."extras") IS NOT NULL
            AND TRIM(d."extras") <> ''
),
effective_base AS (          -- base toppings after removing exclusions
    SELECT  b."order_id",
            b.topping_id
    FROM    base_toppings b
    LEFT JOIN exclusions e
           ON  b."order_id"  = e."order_id"
           AND b.topping_id = e.topping_id
    WHERE   e.topping_id IS NULL
),
all_toppings AS (            -- final list of every topping used (base + extras)
    SELECT topping_id FROM effective_base
    UNION ALL
    SELECT topping_id FROM extras
)
SELECT  pt."topping_name"  AS name,
        COUNT(*)           AS quantity
FROM    all_toppings   at
JOIN    MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
       ON at.topping_id = pt."topping_id"
GROUP BY pt."topping_name"
ORDER BY quantity DESC NULLS LAST;