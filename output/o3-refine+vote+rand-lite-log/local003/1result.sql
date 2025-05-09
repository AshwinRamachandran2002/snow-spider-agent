WITH delivered_orders AS (
    SELECT 
        o."order_id",
        o."customer_id",
        o."order_purchase_timestamp"
    FROM "orders" o
    WHERE o."order_status" = 'delivered'
),
order_amount AS (
    SELECT 
        oi."order_id",
        SUM(oi."price" + oi."freight_value") AS order_sales
    FROM "order_items" oi
    GROUP BY oi."order_id"
),
orders_join AS (
    SELECT 
        d."customer_id",
        d."order_id",
        d."order_purchase_timestamp",
        oa.order_sales
    FROM delivered_orders d
    JOIN order_amount oa 
      ON oa."order_id" = d."order_id"
),
customer_agg AS (
    SELECT
        c."customer_unique_id",
        MAX(o."order_purchase_timestamp") AS latest_purchase,
        COUNT(DISTINCT o."order_id")      AS frequency,
        SUM(o.order_sales)                AS monetary,
        AVG(o.order_sales)                AS avg_sale_per_order
    FROM orders_join o
    JOIN "customers" c 
      ON c."customer_id" = o."customer_id"
    GROUP BY c."customer_unique_id"
),
reference_date AS (
    SELECT MAX(latest_purchase) AS ref_date FROM customer_agg
),
customer_rfm AS (
    SELECT
        ca.*,
        CAST(ROUND(julianday((SELECT ref_date FROM reference_date)) 
             - julianday(ca.latest_purchase)) AS INTEGER) AS recency_days
    FROM customer_agg ca
),
customer_rfm_scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        avg_sale_per_order,
        (5 - NTILE(4) OVER (ORDER BY recency_days ASC))  AS r_score,  -- lower days → higher score
        (5 - NTILE(4) OVER (ORDER BY frequency DESC))    AS f_score,  -- higher freq → higher score
        (5 - NTILE(4) OVER (ORDER BY monetary  DESC))    AS m_score   -- higher spend → higher score
    FROM customer_rfm
),
segmented AS (
    SELECT
        customer_unique_id,
        'R' || r_score || 'F' || f_score || 'M' || m_score AS rfm_segment,
        avg_sale_per_order
    FROM customer_rfm_scored
)
SELECT
    rfm_segment,
    ROUND(AVG(avg_sale_per_order), 4) AS avg_sales_per_order,
    COUNT(*)                          AS customers_in_segment
FROM segmented
GROUP BY rfm_segment
ORDER BY rfm_segment;