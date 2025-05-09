WITH "VALID_ORDERS" AS (
    SELECT
        cco."order_id",
        pn."pizza_name",
        COALESCE(TRIM(cco."extras"),'')          AS "extras"
    FROM MODERN_DATA.MODERN_DATA."PIZZA_CUSTOMER_ORDERS"  cco
    JOIN MODERN_DATA.MODERN_DATA."PIZZA_RUNNER_ORDERS"    pro
          ON cco."order_id" = pro."order_id"
    JOIN MODERN_DATA.MODERN_DATA."PIZZA_NAMES"            pn
          ON cco."pizza_id"  = pn."pizza_id"
    -- keep only completed (not-cancelled) deliveries
    WHERE (pro."cancellation" IS NULL OR TRIM(pro."cancellation") = '')
      AND TRIM(pro."pickup_time") <> ''
      -- only Meat Lovers ($12) and Vegetarian ($10) pizzas
      AND pn."pizza_name" IN ('Meatlovers','Vegetarian')
),  
"CALC_PRICES" AS (    
    SELECT
        "order_id",
        CASE WHEN "pizza_name" = 'Meatlovers'  THEN 12      -- base price
             WHEN "pizza_name" = 'Vegetarian' THEN 10
        END                               AS "base_price",
        /* each extra topping costs $1 */
        IFF("extras" = '',
            0,
            ARRAY_SIZE(SPLIT(REPLACE("extras",' ',''),','))) AS "extra_cnt"
    FROM "VALID_ORDERS"
)
SELECT
    SUM("base_price" + "extra_cnt") AS "total_income"
FROM "CALC_PRICES";