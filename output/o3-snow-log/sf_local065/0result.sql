WITH valid_orders AS (   -- all pizzas that were actually delivered
    SELECT 
        o."order_id",
        o."pizza_id",
        NVL(TRIM(o."extras"),'')             AS "extras_str"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS      o
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RUNNER_ORDERS        r
          ON o."order_id" = r."order_id"
    WHERE NVL(TRIM(r."cancellation"),'') = ''               -- filter-out cancelled
), 

price_lookup AS (         -- map each pizza_id to its menu price
    SELECT 
        "pizza_id",
        CASE 
            WHEN LOWER("pizza_name") LIKE '%meatlovers%'   THEN 12   -- Meat Lovers
            WHEN LOWER("pizza_name") LIKE '%vegetarian%'   THEN 10   -- Vegetarian
            ELSE 0
        END AS "base_price"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_NAMES
),   

per_pizza_revenue AS (     -- work out dollars earned for every pizza row
    SELECT
        v."order_id",
        p."base_price",
        /* count extra toppings: empty → 0, otherwise commas +1          */
        CASE 
            WHEN v."extras_str" = ''                       THEN 0
            ELSE REGEXP_COUNT(REPLACE(v."extras_str",' ',''), ',') + 1
        END                                                AS "extras_cnt"
    FROM valid_orders          v
    LEFT JOIN price_lookup     p
           ON v."pizza_id" = p."pizza_id"
) 

SELECT SUM("base_price" + "extras_cnt")  AS "total_income"
FROM   per_pizza_revenue;