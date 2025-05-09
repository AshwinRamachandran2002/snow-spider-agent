WITH sales_france AS (        /* 1.  2019 & 2020 sales in France with requested filters */
    SELECT
        s."prod_id",
        t."calendar_month_number"          AS month_num,
        t."calendar_year"                  AS sales_year,
        SUM(s."amount_sold")               AS total_amount
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"       s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"  p
           ON s."promo_id" = p."promo_id"
          AND p."promo_total_id" = 1
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"    ch
           ON s."channel_id" = ch."channel_id"
          AND ch."channel_total_id" = 1
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   c
           ON s."cust_id" = c."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   co
           ON c."country_id" = co."country_id"
          AND co."country_name" = 'France'
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"       t
           ON s."time_id" = t."time_id"
    WHERE  t."calendar_year" IN (2019, 2020)
    GROUP BY
        s."prod_id",
        t."calendar_month_number",
        t."calendar_year"
),
prod_growth AS (              /* 2.  growth rate & 2021 projection per product & month */
    SELECT
        f19."prod_id",
        f19.month_num,
        f19.total_amount                              AS sales_2019,
        f20.total_amount                              AS sales_2020,
        CASE
            WHEN f19.total_amount > 0
            THEN (f20.total_amount - f19.total_amount) / f19.total_amount
        END                                           AS growth_rate,
        CASE
            WHEN f19.total_amount > 0
            THEN f20.total_amount * (1 + (f20.total_amount - f19.total_amount) / f19.total_amount)
        END                                           AS projected_2021_local
    FROM   sales_france f19
    JOIN   sales_france f20
           ON f19."prod_id"   = f20."prod_id"
          AND f19.month_num   = f20.month_num
    WHERE  f19.sales_year = 2019
      AND  f20.sales_year = 2020
),
projected_usd AS (            /* 3.  convert 2021 projection to USD using 2021 FX rate */
    SELECT
        pg."prod_id",
        pg.month_num,
        pg.projected_2021_local,
        COALESCE(cur."to_us", 1)                       AS to_us_rate,
        pg.projected_2021_local * COALESCE(cur."to_us", 1)  AS projected_2021_usd
    FROM   prod_growth pg
    LEFT  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
           ON cur."country" = 'France'
          AND cur."year"    = 2021
          AND cur."month"   = pg.month_num
)
SELECT
    month_num                                   AS "MONTH",
    ROUND(AVG(projected_2021_usd), 2)           AS "AVG_PROJECTED_SALES_USD"
FROM   projected_usd
WHERE  projected_2021_usd IS NOT NULL
GROUP BY month_num
ORDER BY month_num;