WITH delivered_orders AS (
    /* all delivered orders, already linked to the unique customer id */
    SELECT  o.order_id,
            c.customer_unique_id,
            o.order_purchase_timestamp
    FROM    orders            AS o
    JOIN    customers         AS c  ON c.customer_id = o.customer_id
    WHERE   o.order_status = 'delivered'
),
order_spend AS (
    /* how much was paid in each delivered order                */
    SELECT  op.order_id,
            SUM(op.payment_value) AS order_spend
    FROM    order_payments AS op
    GROUP BY op.order_id
),
orders_with_spend AS (
    /* combine spend with delivered‑order register               */
    SELECT  d.customer_unique_id,
            d.order_id,
            d.order_purchase_timestamp,
            os.order_spend
    FROM    delivered_orders d
    JOIN    order_spend     os ON os.order_id = d.order_id
),
customer_metrics AS (
    /* R, F, M raw values per customer                           */
    SELECT  customer_unique_id,
            MAX(order_purchase_timestamp)                    AS last_purchase,
            COUNT(*)                                         AS order_count,
            SUM(order_spend)                                 AS total_spend
    FROM    orders_with_spend
    GROUP BY customer_unique_id
),
reference_date AS (
    /* the most recent purchase among ALL delivered orders       */
    SELECT MAX(last_purchase) AS max_date
    FROM   customer_metrics
),
rfm AS (
    /* compute recency in days (smaller = more recent)           */
    SELECT  cm.*,
            CAST(
                julianday((SELECT max_date FROM reference_date))
              - julianday(cm.last_purchase)
            AS INTEGER)                                       AS recency_days
    FROM    customer_metrics cm
),
rfm_scored AS (
    /* quartile scores: R (invert because smaller recency better),
       F (more orders), M (more spend)                          */
    SELECT  customer_unique_id,
            recency_days,
            order_count,
            total_spend,
            total_spend*1.0 / order_count                      AS avg_order_value,
            5 - ntile(4) OVER (ORDER BY recency_days ASC)      AS R_score,
            ntile(4)  OVER (ORDER BY order_count DESC)         AS F_score,
            ntile(4)  OVER (ORDER BY total_spend DESC)         AS M_score
    FROM    rfm
),
rfm_segment AS (
    /* build segment label such as 443, 221, etc.               */
    SELECT  customer_unique_id,
            recency_days,
            order_count,
            total_spend,
            avg_order_value,
            R_score, F_score, M_score,
            CAST(R_score AS TEXT) || CAST(F_score AS TEXT) || CAST(M_score AS TEXT) AS segment
    FROM    rfm_scored
)
SELECT  segment,
        ROUND(AVG(avg_order_value),4)          AS avg_sales_per_order,
        COUNT(*)                               AS customers_in_segment
FROM    rfm_segment
GROUP BY segment
ORDER BY avg_sales_per_order DESC,
         segment;