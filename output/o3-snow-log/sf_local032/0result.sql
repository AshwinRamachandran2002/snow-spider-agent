WITH delivered_sales AS (      -- every item that belongs to a DELIVERED order
    SELECT
        oi."seller_id",
        oi."order_id",
        c."customer_unique_id",
        oi."price",
        oi."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"       o
          ON  oi."order_id" = o."order_id"
          AND o."order_status" = 'delivered'
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS"    c
          ON  o."customer_id" = c."customer_id"
),                                                                  -- #1 – most distinct customers
customer_cnt AS (
    SELECT "seller_id",
           COUNT(DISTINCT "customer_unique_id")        AS cnt_customers
    FROM delivered_sales
    GROUP BY "seller_id"
),                                                                  -- #2 – highest profit
profit_cnt AS (
    SELECT "seller_id",
           SUM("price" - "freight_value")              AS total_profit
    FROM delivered_sales
    GROUP BY "seller_id"
),                                                                  -- #3 – most distinct orders
order_cnt  AS (
    SELECT "seller_id",
           COUNT(DISTINCT "order_id")                  AS cnt_orders
    FROM delivered_sales
    GROUP BY "seller_id"
),                                                                  -- #4 – most 5-star ratings
five_star_cnt AS (
    SELECT ds."seller_id",
           COUNT(CASE WHEN r."review_score" = 5 THEN 1 END)  AS cnt_5star
    FROM delivered_sales ds
    LEFT JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_REVIEWS" r
           ON ds."order_id" = r."order_id"
    GROUP BY ds."seller_id"
),                                                                  -- find the single best seller for each metric
leaders AS (
    SELECT 'Most distinct customer unique IDs' AS achievement,
           "seller_id",
           cnt_customers                        AS value,
           ROW_NUMBER() OVER (ORDER BY cnt_customers DESC, "seller_id") AS rn
    FROM customer_cnt

    UNION ALL

    SELECT 'Highest profit (price – freight)'  AS achievement,
           "seller_id",
           total_profit                        AS value,
           ROW_NUMBER() OVER (ORDER BY total_profit DESC, "seller_id")  AS rn
    FROM profit_cnt

    UNION ALL

    SELECT 'Most distinct orders'              AS achievement,
           "seller_id",
           cnt_orders                          AS value,
           ROW_NUMBER() OVER (ORDER BY cnt_orders DESC, "seller_id")    AS rn
    FROM order_cnt

    UNION ALL

    SELECT 'Most 5-star ratings'               AS achievement,
           "seller_id",
           cnt_5star                           AS value,
           ROW_NUMBER() OVER (ORDER BY cnt_5star DESC, "seller_id")     AS rn
    FROM five_star_cnt
)
SELECT achievement,
       "seller_id",
       value
FROM   leaders
WHERE  rn = 1;