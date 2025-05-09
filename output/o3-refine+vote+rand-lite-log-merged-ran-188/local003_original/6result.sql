WITH delivered_orders AS (
    /* 1. keep only delivered orders and map them to the unique customer id */
    SELECT  o.order_id,
            c.customer_unique_id,
            o.order_purchase_timestamp
    FROM    orders  AS o
    JOIN    customers AS c
           ON c.customer_id = o.customer_id
    WHERE   o.order_status = 'delivered'
),
payments AS (
    /* 2. total amount actually paid for each order */
    SELECT  order_id,
            SUM(payment_value) AS payment_value
    FROM    order_payments
    GROUP BY order_id
),
customer_level AS (
    /* 3. build customer‑level R, F and M raw metrics */
    SELECT  d.customer_unique_id,
            MAX(DATETIME(d.order_purchase_timestamp))           AS last_purchase_ts,
            COUNT(DISTINCT d.order_id)                          AS frequency,
            SUM(p.payment_value)                                AS monetary
    FROM    delivered_orders d
    JOIN    payments        p  ON p.order_id = d.order_id
    GROUP BY d.customer_unique_id
),
reference_date AS (
    /* 4. most recent purchase in the whole data set – used to compute Recency */
    SELECT MAX(last_purchase_ts) AS max_date
    FROM   customer_level
),
add_recency AS (
    /* 5. recency = days since a customer’s latest purchase */
    SELECT  cl.*,
            CAST(
                 JULIANDAY((SELECT max_date FROM reference_date))
               - JULIANDAY(cl.last_purchase_ts)
                 AS INTEGER
            ) AS recency_days
    FROM    customer_level cl
),
scored AS (
    /* 6. score each metric into 5 quintiles: 
          – lower Recency (fewer days) is better
          – higher Frequency / Monetary is better */
    SELECT  customer_unique_id,
            recency_days,
            frequency,
            monetary,
            NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
            NTILE(5) OVER (ORDER BY frequency   DESC)  AS f_score,
            NTILE(5) OVER (ORDER BY monetary    DESC)  AS m_score
    FROM    add_recency
),
segment_tagged AS (
    /* 7. concatenate the individual scores to obtain the RFM segment code */
    SELECT  customer_unique_id,
            CAST(r_score AS TEXT) || CAST(f_score AS TEXT) || CAST(m_score AS TEXT) 
              AS rfm_segment,
            frequency,
            monetary
    FROM    scored
)
/* 8. final report – average sales per order inside each RFM segment */
SELECT  rfm_segment,
        ROUND(SUM(monetary) * 1.0 / SUM(frequency), 4) AS avg_sales_per_order,
        COUNT(DISTINCT customer_unique_id)            AS customers_in_segment
FROM    segment_tagged
GROUP BY rfm_segment
ORDER BY rfm_segment;