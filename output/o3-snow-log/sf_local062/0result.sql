WITH italian_customer_monthly_profit AS (
    /* 1.  Profit per Italian customer for December-2021 */
    SELECT
        s."cust_id",
        SUM( s."quantity_sold"
             * (cst."unit_price" - cst."unit_cost") ) AS total_profit
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"      s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  cu  ON cu."cust_id"  = s."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  co  ON co."country_id" = cu."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"      t   ON t."time_id"   = s."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS"      cst ON cst."prod_id"  = s."prod_id"
                                                       AND cst."channel_id" = s."channel_id"
                                                       AND cst."promo_id"   = s."promo_id"
                                                       AND cst."time_id"    = s."time_id"
    WHERE co."country_name" = 'Italy'
      AND t."calendar_year"         = 2021
      AND t."calendar_month_number" = 12
    GROUP BY s."cust_id"
),
profit_bounds AS (
    /* 2.  Overall min / max profit among Italian customers for the month */
    SELECT
        MIN(total_profit) AS min_profit,
        MAX(total_profit) AS max_profit
    FROM italian_customer_monthly_profit
),
bucketed_profits AS (
    /* 3.  Place each customer into one of ten equal-width buckets            */
    SELECT
        p."cust_id",
        p.total_profit,
        CASE
            WHEN b.max_profit = b.min_profit          -- all customers have same profit
                 THEN 1
            ELSE LEAST(                                -- ensure upper bound goes to bucket 10
                     10,
                     FLOOR( (p.total_profit - b.min_profit) /
                            ( (b.max_profit - b.min_profit) / 10 ) ) + 1
                 )
        END AS bucket_no
    FROM italian_customer_monthly_profit p
    CROSS JOIN profit_bounds b
)
SELECT
    bucket_no                               AS bucket,
    COUNT(*)                                AS customer_count,
    MIN(total_profit)                       AS bucket_min_profit,
    MAX(total_profit)                       AS bucket_max_profit
FROM bucketed_profits
GROUP BY bucket_no
ORDER BY bucket_no;