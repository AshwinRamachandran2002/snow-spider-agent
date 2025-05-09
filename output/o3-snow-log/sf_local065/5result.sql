WITH delivered_orders AS (          -- only keep orders that were actually delivered
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS
    WHERE "cancellation" = ''              -- not cancelled
      AND "pickup_time" IS NOT NULL
      AND "pickup_time" <> ''
),
pizza_prices AS (                   -- assign the menu price to the two pizzas we care about
    SELECT  "pizza_id",
            CASE
                WHEN LOWER("pizza_name") LIKE '%meatlovers%'  THEN 12      -- Meat Lovers
                WHEN LOWER("pizza_name") LIKE '%vegetarian%'  THEN 10      -- Vegetarian
            END AS "unit_price"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_NAMES
    WHERE LOWER("pizza_name") LIKE '%meatlovers%' 
       OR LOWER("pizza_name") LIKE '%vegetarian%'
),
pizzas_sold AS (                    -- every individual pizza sold (one row = one pizza)
    SELECT  c."order_id",
            pp."unit_price"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS c
    JOIN delivered_orders        d  ON d."order_id" = c."order_id"
    JOIN pizza_prices            pp ON pp."pizza_id" = c."pizza_id"
),
order_pizza_totals AS (             -- total pizza revenue per order
    SELECT  "order_id",
            SUM("unit_price") AS "pizza_revenue"
    FROM pizzas_sold
    GROUP BY "order_id"
),
order_extras AS (                   -- $1 for every extra topping on the order
    SELECT  e."order_id",
            COUNT(*) AS "extras_revenue"   -- 1 dollar per extra row
    FROM MODERN_DATA.MODERN_DATA.PIZZA_GET_EXTRAS e
    JOIN delivered_orders d ON d."order_id" = e."order_id"
    GROUP BY e."order_id"
),
order_revenue AS (                  -- final revenue per order
    SELECT  p."order_id",
            p."pizza_revenue",
            COALESCE(x."extras_revenue",0)                    AS "extras_revenue",
            p."pizza_revenue" + COALESCE(x."extras_revenue",0) AS "total_order_revenue"
    FROM order_pizza_totals p
    LEFT JOIN order_extras   x ON x."order_id" = p."order_id"
)
SELECT  SUM("total_order_revenue") AS "total_income"
FROM order_revenue;