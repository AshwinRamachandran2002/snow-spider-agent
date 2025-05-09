/*  Calculate Pizza Runner’s total revenue from delivered
    Meat Lovers ($12) and Vegetarian ($10) pizzas,
    adding $1 for every extra topping on each pizza        */

WITH delivered_orders AS (
     SELECT 
            o."order_id",
            n."pizza_name",
            /* count extras on each pizza row */
            CASE 
                 WHEN TRIM(o."extras") = '' OR o."extras" IS NULL THEN 0
                 ELSE ARRAY_SIZE(SPLIT(REGEXP_REPLACE(o."extras", '\\s', ''), ',')) 
            END                                            AS extras_cnt
     FROM  MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS o
     JOIN  MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS  r
           ON  o."order_id" = r."order_id"
          AND r."cancellation" = ''                         -- keep only non-cancelled
     JOIN  MODERN_DATA.MODERN_DATA.PIZZA_NAMES              n
           ON  o."pizza_id" = n."pizza_id"
     WHERE LOWER(n."pizza_name") IN ('meatlovers','vegetarian')
)
SELECT SUM(
           CASE 
                 WHEN LOWER("pizza_name") = 'meatlovers'  THEN 12
                 WHEN LOWER("pizza_name") = 'vegetarian'  THEN 10
           END
           + extras_cnt                                    -- $1 per extra topping
          )  AS total_income
FROM   delivered_orders;