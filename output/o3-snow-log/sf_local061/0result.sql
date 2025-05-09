/* Average projected monthly sales in USD for France – 2021 */
WITH sales_fr AS (        -- 1.  France sales in 2019-2020 (promo_total_id = 1, channel_total_id = 1)
    SELECT
        s."prod_id",
        t."calendar_month_number" AS "month_num",
        t."calendar_year"         AS "year",
        SUM(s."amount_sold")      AS "amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"      s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"      t  ON s."time_id"    = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  c  ON s."cust_id"    = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  cn ON c."country_id" = cn."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"   ch ON s."channel_id" = ch."channel_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS" p  ON s."promo_id"   = p."promo_id"
    WHERE cn."country_name"     = 'France'
      AND ch."channel_total_id" = 1
      AND p."promo_total_id"    = 1
      AND t."calendar_year" IN (2019, 2020)
    GROUP BY
        s."prod_id",
        t."calendar_month_number",
        t."calendar_year"
),
join_years AS (           -- 2.  Match 2019 and 2020 sales for the same product & month
    SELECT
        y20."prod_id",
        y20."month_num",
        y19."amount_sold" AS "amt_2019",
        y20."amount_sold" AS "amt_2020"
    FROM sales_fr y19
    JOIN sales_fr y20
          ON y19."prod_id"   = y20."prod_id"
         AND y19."month_num" = y20."month_num"
    WHERE y19."year" = 2019
      AND y20."year" = 2020
),
proj_2021 AS (            -- 3.  Project 2021 sales (local currency)
    SELECT
        j."prod_id",
        j."month_num",
        CASE
            WHEN j."amt_2019" <> 0 THEN
                 ((j."amt_2020" - j."amt_2019") / j."amt_2019") * j."amt_2020" + j."amt_2020"
            ELSE NULL
        END AS "projected_local"
    FROM join_years j
),
proj_2021_usd AS (        -- 4.  Convert to USD using 2021 FX rates
    SELECT
        p."month_num",
        p."prod_id",
        p."projected_local" * COALESCE(cur."to_us", 1) AS "projected_usd"
    FROM proj_2021 p
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
           ON cur."country" = 'France'
          AND cur."year"    = 2021
          AND cur."month"   = p."month_num"
)
-- 5.  Average projected sales per month
SELECT
    "month_num",
    ROUND(AVG("projected_usd"), 2) AS "avg_projected_sales_usd"
FROM proj_2021_usd
GROUP BY "month_num"
ORDER BY "month_num";