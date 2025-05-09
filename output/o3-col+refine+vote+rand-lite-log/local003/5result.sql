/* ---------------------------------------------------------------
   Average sales per order (Monetary / #Orders) for every customer,
   grouped by R-F-M segment – delivered orders only
   ----------------------------------------------------------------
   Recency  : days since customer’s last delivered purchase
              = MAX(order_purchase_timestamp in data set)
                − last_purchase_timestamp_of_customer
   Frequency: # delivered orders made by the customer
   Monetary : Σ(price + freight) of delivered orders

   Scoring rules (1-4, best = 4)
   --------------------------------
   R (Recency – lower is better)
       ≤  30 days → 4
       ≤  90 days → 3
       ≤ 180 days → 2
       else       → 1
   F (Frequency – higher is better)
       ≥ 10 orders → 4
       ≥  5 orders → 3
       ≥  2 orders → 2
       else        → 1
   M (Monetary – higher is better)
       > 1000 BRL → 4
       >  500 BRL → 3
       >  100 BRL → 2
       else       → 1
   ---------------------------------------------------------------- */
WITH delivered_orders AS (
    SELECT  o."order_id",
            o."customer_id",
            o."order_purchase_timestamp"
    FROM    "orders" AS o
    WHERE   o."order_status" = 'delivered'
),
cust_metrics AS (            -- F & M & last purchase
    SELECT  cu."customer_unique_id",
            COUNT(DISTINCT d."order_id")                       AS "frequency",
            SUM(oi."price" + oi."freight_value")               AS "monetary",
            MAX(d."order_purchase_timestamp")                  AS "last_purchase"
    FROM        delivered_orders  AS d
    JOIN        "customers"       AS cu ON cu."customer_id" = d."customer_id"
    JOIN        "order_items"     AS oi ON oi."order_id"    = d."order_id"
    GROUP BY    cu."customer_unique_id"
),
recency_calc AS (            -- add Recency in days
    SELECT  cm.*,
            ( julianday( (SELECT MAX("order_purchase_timestamp") FROM "orders") )
              - julianday(cm."last_purchase") )                AS "recency_days"
    FROM    cust_metrics cm
),
rfm_scored AS (              -- assign R, F, M scores + average sales/order
    SELECT  rc.*,
            CASE WHEN recency_days <=  30 THEN 4
                 WHEN recency_days <=  90 THEN 3
                 WHEN recency_days <= 180 THEN 2
                 ELSE                           1 END          AS "R_score",
            CASE WHEN frequency >= 10 THEN 4
                 WHEN frequency >=  5 THEN 3
                 WHEN frequency >=  2 THEN 2
                 ELSE                   1 END                  AS "F_score",
            CASE WHEN monetary  > 1000 THEN 4
                 WHEN monetary  >  500 THEN 3
                 WHEN monetary  >  100 THEN 2
                 ELSE                       1 END              AS "M_score",
            monetary * 1.0 / frequency                         AS "avg_sales_per_order"
    FROM    recency_calc rc
),
rfm_segmented AS (           -- compress the three scores into one label
    SELECT  customer_unique_id,
            avg_sales_per_order,
            CAST(R_score AS TEXT) || CAST(F_score AS TEXT) || CAST(M_score AS TEXT)
                AS "RFM_segment"
    FROM    rfm_scored
)
SELECT  RFM_segment,
        COUNT(DISTINCT customer_unique_id)          AS n_customers,
        ROUND(AVG(avg_sales_per_order),4)           AS avg_sales_per_order
FROM    rfm_segmented
GROUP BY RFM_segment
ORDER BY avg_sales_per_order DESC;