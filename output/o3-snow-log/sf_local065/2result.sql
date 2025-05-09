WITH delivered_orders AS (   -- keep only orders that were actually delivered
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RUNNER_ORDERS
    WHERE COALESCE(TRIM("cancellation"),'') = ''
),

priced_pizzas AS (          -- attach pizza name & price and keep only Meat Lovers / Vegetarian
    SELECT
        c."order_id",
        c."pizza_id",
        c."extras",
        n."pizza_name",
        CASE
            WHEN LOWER(n."pizza_name")   = 'meatlovers'  THEN 12     -- Meat Lovers price
            WHEN LOWER(n."pizza_name")   = 'vegetarian'  THEN 10     -- Vegetarian price
        END                                                    AS "base_price"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS  c
    JOIN delivered_orders                               d  ON c."order_id" = d."order_id"
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES            n  ON c."pizza_id" = n."pizza_id"
    WHERE LOWER(n."pizza_name") IN ('meatlovers','vegetarian')
),

pizza_with_extras AS (      -- count $1 extras on each pizza row
    SELECT
        "order_id",
        "base_price",
        CASE
            WHEN COALESCE(TRIM("extras"),'') = '' THEN 0
            ELSE 1 + REGEXP_COUNT(REGEXP_REPLACE(TRIM("extras"),'\\s',''), ',')
        END                                                AS "extras_cnt"
    FROM priced_pizzas
)

SELECT
    SUM("base_price" + "extras_cnt")   AS "total_income"
FROM pizza_with_extras;