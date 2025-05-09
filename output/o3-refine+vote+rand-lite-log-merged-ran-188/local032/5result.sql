WITH delivered AS (
    SELECT "order_id",
           "customer_id"
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
),
base AS (
    SELECT d."order_id",
           d."customer_id",
           oi."seller_id",
           oi."price",
           oi."freight_value"
    FROM   delivered            AS d
    JOIN   "olist_order_items"  AS oi
           ON d."order_id" = oi."order_id"
),
metrics AS (
    SELECT  b."seller_id",
            COUNT(DISTINCT c."customer_unique_id")            AS distinct_customers,
            SUM(b."price" - b."freight_value")                AS total_profit,
            COUNT(DISTINCT b."order_id")                      AS distinct_orders
    FROM    base                   AS b
    JOIN    "olist_customers"      AS c
            ON b."customer_id" = c."customer_id"
    GROUP BY b."seller_id"
),
five_stars AS (
    SELECT  oi."seller_id",
            COUNT(*) AS five_star_count
    FROM    "olist_order_reviews" AS r
    JOIN    "olist_order_items"   AS oi ON r."order_id" = oi."order_id"
    JOIN    "olist_orders"        AS o  ON r."order_id" = o."order_id"
    WHERE   o."order_status" = 'delivered'
      AND   r."review_score" = 5
    GROUP BY oi."seller_id"
)

SELECT 'Most distinct customer_unique_id' AS description,
       m."seller_id",
       m."distinct_customers"             AS value
FROM   metrics AS m
WHERE  m."distinct_customers" = (SELECT MAX(distinct_customers) FROM metrics)

UNION ALL
SELECT 'Highest profit',
       m."seller_id",
       m."total_profit"
FROM   metrics AS m
WHERE  m."total_profit" = (SELECT MAX(total_profit) FROM metrics)

UNION ALL
SELECT 'Most distinct orders',
       m."seller_id",
       m."distinct_orders"
FROM   metrics AS m
WHERE  m."distinct_orders" = (SELECT MAX(distinct_orders) FROM metrics)

UNION ALL
SELECT 'Most 5-star ratings',
       f."seller_id",
       f."five_star_count"
FROM   five_stars AS f
WHERE  f."five_star_count" = (SELECT MAX(five_star_count) FROM five_stars);