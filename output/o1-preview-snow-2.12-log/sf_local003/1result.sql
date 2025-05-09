WITH customer_orders AS (
    SELECT
        o."customer_id",
        COUNT(DISTINCT o."order_id") AS "frequency",
        SUM(oi."price") AS "monetary",
        MAX(DATE(o."order_purchase_timestamp")) AS "last_purchase_date"
    FROM E_COMMERCE.E_COMMERCE.ORDERS o
    INNER JOIN E_COMMERCE.E_COMMERCE.ORDER_ITEMS oi ON o."order_id" = oi."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY o."customer_id"
),
rfm_metrics AS (
    SELECT
        "customer_id",
        "frequency",
        "monetary",
        "last_purchase_date",
        DATEDIFF('day', "last_purchase_date", DATE('2018-10-17')) AS "recency"
    FROM customer_orders
),
rfm_scores AS (
    SELECT
        "customer_id",
        "recency",
        "frequency",
        "monetary",
        NTILE(5) OVER (ORDER BY "recency" ASC NULLS LAST) AS "recency_score",
        NTILE(5) OVER (ORDER BY "frequency" DESC NULLS LAST) AS "frequency_score",
        NTILE(5) OVER (ORDER BY "monetary" DESC NULLS LAST) AS "monetary_score"
    FROM rfm_metrics
),
rfm_classification AS (
    SELECT
        *,
        CASE
            WHEN "recency_score" = 5 AND "frequency_score" >= 4 AND "monetary_score" >= 4 THEN 'Champions'
            WHEN "recency_score" = 1 AND "frequency_score" >= 4 AND "monetary_score" >= 4 THEN 'Can''t Lose Them'
            WHEN "recency_score" = 1 AND "frequency_score" BETWEEN 2 AND 3 AND "monetary_score" BETWEEN 2 AND 3 THEN 'Hibernating'
            WHEN "recency_score" = 1 AND "frequency_score" <= 1 AND "monetary_score" <= 1 THEN 'Lost'
            WHEN "recency_score" BETWEEN 3 AND 4 AND "frequency_score" >= 4 AND "monetary_score" >= 4 THEN 'Loyal Customers'
            WHEN "recency_score" = 3 AND "frequency_score" BETWEEN 2 AND 3 AND "monetary_score" BETWEEN 2 AND 3 THEN 'Needs Attention'
            WHEN "recency_score" = 5 AND "frequency_score" BETWEEN 2 AND 3 AND "monetary_score" BETWEEN 2 AND 3 THEN 'Recent Users'
            WHEN ("recency_score" IN (4, 5) AND "frequency_score" BETWEEN 3 AND 4 AND "monetary_score" BETWEEN 3 AND 4) THEN 'Potential Loyalists'
            WHEN "recency_score" = 5 AND "frequency_score" <= 2 AND "monetary_score" <= 2 THEN 'Price Sensitive'
            WHEN "recency_score" = 4 AND "frequency_score" <= 3 AND "monetary_score" <= 3 THEN 'Promising'
            WHEN "recency_score" = 3 AND "frequency_score" <= 2 AND "monetary_score" <= 2 THEN 'About to Sleep'
            ELSE 'Others'
        END AS "RFM_Segment"
    FROM rfm_scores
)
SELECT
    "RFM_Segment",
    ROUND(AVG("monetary" / NULLIF("frequency", 0)), 4) AS "Average_Sales_Per_Order"
FROM rfm_classification
GROUP BY "RFM_Segment"
ORDER BY "RFM_Segment" ASC NULLS LAST;