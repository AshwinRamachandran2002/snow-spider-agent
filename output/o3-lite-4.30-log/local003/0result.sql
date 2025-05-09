WITH delivered_orders AS (
    SELECT  o.order_id,
            c.customer_unique_id,
            DATE(o.order_purchase_timestamp)          AS purchase_date,
            op.payment_value
    FROM    orders          AS o
    JOIN    customers       AS c  ON c.customer_id  = o.customer_id
    JOIN    order_payments  AS op ON op.order_id    = o.order_id
    WHERE   o.order_status = 'delivered'
),
anchor AS (
    SELECT DATE(MAX(purchase_date)) AS max_date
    FROM   delivered_orders
),
rfm_raw AS (
    SELECT  customer_unique_id,
            CAST(julianday((SELECT max_date FROM anchor)) -
                 julianday(MAX(purchase_date)) AS INTEGER)  AS recency_days,
            COUNT(DISTINCT order_id)                                    AS frequency,
            SUM(payment_value)                                          AS monetary,
            SUM(payment_value) * 1.0 / COUNT(DISTINCT order_id)         AS avg_sales_per_order
    FROM    delivered_orders
    GROUP   BY customer_unique_id
),
rfm_scores AS (
    SELECT  *,
            6 - NTILE(5) OVER (ORDER BY recency_days ASC)  AS R_score,
            NTILE(5)    OVER (ORDER BY frequency DESC)     AS F_score,
            NTILE(5)    OVER (ORDER BY monetary  DESC)     AS M_score
    FROM    rfm_raw
),
segment_map AS (
    SELECT  customer_unique_id,
            avg_sales_per_order,
            CASE
                WHEN R_score>=4 AND F_score>=4 AND M_score>=4 THEN 'Champions'
                WHEN R_score>=3 AND F_score>=4                 THEN 'Loyal'
                WHEN R_score>=4 AND F_score<=3 AND M_score<=3 THEN 'Potential'
                WHEN R_score<=2                                THEN 'At Risk'
                ELSE                                               'Sleepers'
            END AS rfm_segment
    FROM    rfm_scores
),
segment_stats AS (
    SELECT  rfm_segment,
            ROUND(AVG(avg_sales_per_order), 4) AS average_sales_per_order
    FROM    segment_map
    GROUP   BY rfm_segment
),
overall AS (
    SELECT ROUND(AVG(avg_sales_per_order), 4) AS overall_average
    FROM   segment_map
)
SELECT  s.rfm_segment,
        s.average_sales_per_order,
        ROUND(s.average_sales_per_order - (SELECT overall_average FROM overall), 4)
        AS vs_overall_average
FROM    segment_stats AS s
ORDER   BY s.average_sales_per_order DESC, s.rfm_segment;