/* 1.  Keep only orders that were actually delivered (no cancellation)
   2.  Pick the two pizzas we need, attach their prices
   3.  Work out how many $1 extras were added to each pizza
   4.  Add pizza-price + extras and total everything up                      */
WITH non_cancelled_orders AS (
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA."PIZZA_CLEAN_RUNNER_ORDERS"
    WHERE COALESCE("cancellation",'') = ''          -- filter out all cancellations
),
priced_pizzas AS (
    SELECT
        o."order_id",
        pn."pizza_name",
        /* base price for each required pizza */
        CASE 
            WHEN LOWER(pn."pizza_name") LIKE 'meatlovers%'  THEN 12
            WHEN LOWER(pn."pizza_name") LIKE 'vegetarian%'  THEN 10
        END                                   AS base_price,
        /* number of extra toppings ($1 each) */
        CASE 
            WHEN o."extras" IS NULL OR TRIM(o."extras") = '' THEN 0
            ELSE ARRAY_SIZE( SPLIT( REPLACE(o."extras",' ',''), ',' ) )
        END                                   AS extras_cnt
    FROM MODERN_DATA.MODERN_DATA."PIZZA_CLEAN_CUSTOMER_ORDERS" o
    JOIN non_cancelled_orders nc
         ON o."order_id" = nc."order_id"
    JOIN MODERN_DATA.MODERN_DATA."PIZZA_NAMES" pn
         ON o."pizza_id" = pn."pizza_id"
    WHERE LOWER(pn."pizza_name") IN ('meatlovers','vegetarian')
)
SELECT SUM(base_price + extras_cnt) AS total_income
FROM priced_pizzas;