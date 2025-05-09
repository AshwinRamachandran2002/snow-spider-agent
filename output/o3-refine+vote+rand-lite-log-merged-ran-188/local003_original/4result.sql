WITH delivered_orders AS (
    /* 1. keep only delivered orders and tie them to the unique customer id   */
    SELECT  o.order_id,
            c.customer_unique_id,
            o.order_purchase_timestamp
    FROM    orders            AS o
    JOIN    customers         AS c   ON c.customer_id = o.customer_id
    WHERE   o.order_status = 'delivered'
),
order_total_payments AS (
    /* 2. total value paid per order                                          */
    SELECT  order_id,
            SUM(payment_value) AS order_payment_value
    FROM    order_payments
    GROUP BY order_id
),
orders_enriched AS (
    /* 3. merge value with delivered orders                                   */
    SELECT  d.customer_unique_id,
            d.order_id,
            d.order_purchase_timestamp,
            p.order_payment_value
    FROM    delivered_orders      AS d
    JOIN    order_total_payments  AS p  USING (order_id)
),
customer_level AS (
    /* 4. one row per customer: Recency (latest purchase), Frequency, Monetary*/
    SELECT  customer_unique_id,
            MAX(order_purchase_timestamp)                    AS last_purchase_ts,
            COUNT(DISTINCT order_id)                         AS frequency_orders,
            SUM(order_payment_value)                         AS monetary_total
    FROM    orders_enriched
    GROUP BY customer_unique_id
),
reference_date AS (
    /* most recent purchase in the whole base – used for recency in days      */
    SELECT MAX(last_purchase_ts) AS global_max_ts
    FROM   customer_level
),
customer_rfm AS (
    /* 5. Recency in days                                                     */
    SELECT  cl.*,
            CAST( julianday((SELECT global_max_ts FROM reference_date))
                - julianday(last_purchase_ts)                AS INTEGER )  AS recency_days
    FROM    customer_level AS cl
),
scored_rfm AS (
    /* 6. score each metric into quintiles (1–5).  
          For Recency, lower = better, hence we reverse the ntile result      */
    SELECT  customer_unique_id,
            recency_days,
            frequency_orders,
            monetary_total,
            (6 - NTILE(5) OVER (ORDER BY recency_days ASC )) AS r_score,
            NTILE(5) OVER (ORDER BY frequency_orders DESC)   AS f_score,
            NTILE(5) OVER (ORDER BY monetary_total   DESC)   AS m_score
    FROM    customer_rfm
),
segmented AS (
    /* 7. build the RFM segment code and customer‑level average sales/order   */
    SELECT  customer_unique_id,
            (r_score || f_score || m_score)                     AS rfm_segment,
            monetary_total * 1.0 / frequency_orders             AS avg_sales_per_order
    FROM    scored_rfm
)
/* 8. compare average sales per order across the distinct RFM segments        */
SELECT  rfm_segment,
        COUNT(*)                           AS customers_in_segment,
        ROUND(AVG(avg_sales_per_order),4)  AS avg_sales_per_order_segment
FROM    segmented
GROUP BY rfm_segment
ORDER BY rfm_segment;