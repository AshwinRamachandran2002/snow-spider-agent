/* -----------------------------------------------------------
   1) Find the most recent “delivered” purchase in the dataset
------------------------------------------------------------*/
WITH latest_date AS (
    SELECT MAX("order_purchase_timestamp") AS max_ts
    FROM   "orders"
    WHERE  "order_status" = 'delivered'
),

/* -----------------------------------------------------------
   2) For every customer (identified by customer_unique_id)
      – Recency  : days since last delivered order
      – Frequency: number of delivered orders
      – Monetary : total value (price + freight)
------------------------------------------------------------*/
customer_rfm AS (
    SELECT  c."customer_unique_id",
            ROUND(
                julianday( (SELECT max_ts FROM latest_date) )
              - julianday( MAX(o."order_purchase_timestamp") )
            ,1)                                     AS recency_days,
            COUNT(DISTINCT o."order_id")            AS frequency,
            SUM(oi."price" + oi."freight_value")    AS monetary
    FROM      "orders"       o
    JOIN      "order_items"  oi  ON oi."order_id"  = o."order_id"
    JOIN      "customers"    c   ON c."customer_id"= o."customer_id"
    WHERE     o."order_status" = 'delivered'
    GROUP BY  c."customer_unique_id"
),

/* -----------------------------------------------------------
   3) Score each metric by terciles (NTILE(3))
      – For Recency, lower days = better so score inverted
      – For Frequency & Monetary, higher = better
------------------------------------------------------------*/
scored_rfm AS (
    SELECT *,
           /* R score: 3 (best) … 1 (worst) */
           4 - NTILE(3) OVER (ORDER BY recency_days ASC)  AS r_score,
           /* F score: 1 (worst) … 3 (best) */
           NTILE(3) OVER (ORDER BY frequency DESC)        AS f_score,
           /* M score: 1 (worst) … 3 (best) */
           NTILE(3) OVER (ORDER BY monetary DESC)         AS m_score,
           /* average sales per order for the customer */
           ROUND(monetary * 1.0 / frequency,4)            AS avg_sales_per_order
    FROM   customer_rfm
),

/* -----------------------------------------------------------
   4) Build the concatenated RFM segment code (e.g., “331”)
------------------------------------------------------------*/
segmented AS (
    SELECT *,
           CAST(r_score AS TEXT) || CAST(f_score AS TEXT) || CAST(m_score AS TEXT)
           AS rfm_segment
    FROM   scored_rfm
)

/* -----------------------------------------------------------
   5) Report: average sales per order inside every RFM segment
------------------------------------------------------------*/
SELECT  rfm_segment,
        COUNT(*)                              AS customers_in_segment,
        ROUND(AVG(avg_sales_per_order),4)     AS avg_sales_per_order_segment
FROM    segmented
GROUP BY rfm_segment
ORDER BY rfm_segment;