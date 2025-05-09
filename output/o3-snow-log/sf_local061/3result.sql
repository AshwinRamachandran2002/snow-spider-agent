WITH sales_filtered AS (   -- 2019-2020 sales for France, promo_total_id = 1, channel_total_id = 1
    SELECT
        s."prod_id",
        YEAR(TO_DATE(s."time_id"))                          AS sales_year,
        MONTH(TO_DATE(s."time_id"))                         AS month_num,
        SUM(s."amount_sold")                                AS amount_sold
    FROM  COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"        s
    JOIN  COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"    cu  ON s."cust_id"   = cu."cust_id"
    JOIN  COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"    co  ON cu."country_id" = co."country_id"
    JOIN  COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"   p   ON s."promo_id"  = p."promo_id"
    JOIN  COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"     ch  ON s."channel_id" = ch."channel_id"
    WHERE  co."country_name" = 'France'
      AND  p."promo_total_id" = 1
      AND  ch."channel_total_id" = 1
      AND  YEAR(TO_DATE(s."time_id")) IN (2019, 2020)
    GROUP BY
        s."prod_id",
        YEAR(TO_DATE(s."time_id")),
        MONTH(TO_DATE(s."time_id"))
),
sales_2019 AS (
    SELECT * FROM sales_filtered WHERE sales_year = 2019
),
sales_2020 AS (
    SELECT * FROM sales_filtered WHERE sales_year = 2020
),
growth_calc AS (          -- project 2021 sales per product & month
    SELECT
        s20."prod_id",
        s20.month_num,
        s19.amount_sold                                     AS amount_2019,
        s20.amount_sold                                     AS amount_2020,
        CASE
            WHEN s19.amount_sold <> 0 THEN
                 (((s20.amount_sold - s19.amount_sold) / s19.amount_sold) * s20.amount_sold) 
               +  s20.amount_sold                           -- projection formula
            ELSE NULL
        END                                                 AS projected_2021_local
    FROM sales_2020 s20
    JOIN sales_2019 s19
      ON s20."prod_id"  = s19."prod_id"
     AND s20.month_num  = s19.month_num
),
proj_usd AS (            -- convert projected sales to USD using 2021 FX rate
    SELECT
        g."prod_id",
        g.month_num,
        g.projected_2021_local,
        COALESCE(cur."to_us", 1)                            AS to_us_rate,
        g.projected_2021_local * COALESCE(cur."to_us", 1)   AS projected_2021_usd
    FROM growth_calc g
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
           ON cur."country" = 'France'
          AND cur."year"    = 2021
          AND cur."month"   = g.month_num
)
SELECT                                                         -- average projected monthly sales in USD
    TO_CHAR(TO_DATE('2021-' || LPAD(month_num,2,'0') || '-01'), 'YYYY-MM')  
                                                             AS "month",
    ROUND(AVG(projected_2021_usd), 2)                       AS "avg_projected_sales_usd"
FROM proj_usd
GROUP BY month_num
ORDER BY month_num;