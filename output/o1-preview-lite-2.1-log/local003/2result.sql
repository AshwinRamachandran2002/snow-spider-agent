SELECT "RFM_Segment", AVG("avg_sales_per_order") AS "Average_Sales_Per_Order"
FROM (
    SELECT
        (CASE
            WHEN recency_days <= 30 THEN 'Recent'
            WHEN recency_days <= 90 THEN 'Active'
            ELSE 'Inactive'
        END || '-' ||
        CASE
            WHEN frequency >= 5 THEN 'Frequent'
            WHEN frequency BETWEEN 2 AND 4 THEN 'Regular'
            ELSE 'Infrequent'
        END || '-' ||
        CASE
            WHEN monetary_value >= 1000 THEN 'High'
            WHEN monetary_value >= 500 THEN 'Medium'
            ELSE 'Low'
        END) AS "RFM_Segment",
        ("monetary_value" / "frequency") AS "avg_sales_per_order"
    FROM (
        SELECT o."customer_id",
               JULIANDAY('2018-10-17') - JULIANDAY(MAX(o."order_purchase_timestamp")) AS "recency_days",
               COUNT(DISTINCT o."order_id") AS "frequency",
               SUM(oi."price") AS "monetary_value"
        FROM "orders" o
        JOIN "order_items" oi ON o."order_id" = oi."order_id"
        WHERE o."order_status" = 'delivered'
        GROUP BY o."customer_id"
    ) AS customer_rfm
) AS customer_avg_sales
GROUP BY "RFM_Segment";