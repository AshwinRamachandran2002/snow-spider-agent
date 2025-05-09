WITH delivered_order_values AS (
    /* 1.  Every delivered order with its value */
    SELECT   o.order_id,
             o.order_purchase_timestamp,
             c.customer_unique_id,
             SUM(oi.price + oi.freight_value)            AS order_value
    FROM     orders        AS o
    JOIN     order_items   AS oi ON oi.order_id = o.order_id
    JOIN     customers     AS c  ON c.customer_id = o.customer_id
    WHERE    o.order_status = 'delivered'
    GROUP BY o.order_id
),
reference_date AS (
    /* 2.  Use the most recent delivered purchase as “today” */
    SELECT MAX(order_purchase_timestamp) AS ref_date
    FROM   delivered_order_values
),
customer_rfm AS (
    /* 3.  R, F, M and average sales per customer */
    SELECT  d.customer_unique_id,
            CAST(
                 julianday( (SELECT ref_date FROM reference_date) ) -
                 julianday( MAX(d.order_purchase_timestamp) )
                 AS INTEGER)                         AS recency_days,
            COUNT(DISTINCT d.order_id)               AS frequency,
            SUM(d.order_value)                       AS monetary,
            ROUND( SUM(d.order_value) * 1.0 /
                   COUNT(DISTINCT d.order_id), 4)    AS avg_sales_per_order
    FROM    delivered_order_values AS d
    GROUP BY d.customer_unique_id
),
scored AS (
    /* 4.  R, F, M scores – simple business thresholds          */
    SELECT *,
           CASE
                WHEN recency_days <=  30 THEN 4
                WHEN recency_days <=  90 THEN 3
                WHEN recency_days <= 180 THEN 2
                ELSE                              1
           END                                       AS R_score,
           CASE
                WHEN frequency >= 10 THEN 4
                WHEN frequency >=  5 THEN 3
                WHEN frequency >=  2 THEN 2
                ELSE                    1
           END                                       AS F_score,
           CASE
                WHEN monetary >= 1000 THEN 4
                WHEN monetary >=  500 THEN 3
                WHEN monetary >=  100 THEN 2
                ELSE                      1
           END                                       AS M_score
    FROM   customer_rfm
),
segmented AS (
    /* 5. Segment names derived from the R, F, M combinations   */
    SELECT *,
           CASE
                WHEN R_score = 4 AND F_score = 4 AND M_score = 4              THEN 'Champions'
                WHEN R_score >=3 AND F_score >=3 AND M_score >=3              THEN 'Loyal'
                WHEN R_score IN (4,3) AND F_score <=2 AND M_score <=2         THEN 'Potential'
                ELSE                                                               'Others'
           END AS RFM_segment
    FROM   scored
)
/* 6.  Average sales per order inside every RFM segment */
SELECT  RFM_segment,
        COUNT(DISTINCT customer_unique_id)                AS customers,
        ROUND( AVG(avg_sales_per_order), 4)               AS avg_sales_per_order
FROM    segmented
GROUP BY RFM_segment
ORDER BY avg_sales_per_order DESC,
         RFM_segment;