WITH fr_sales AS (   -- 1.  France sales for 2019-2020 (promo_total_id = 1, channel_total_id = 1)
    SELECT
        s."prod_id",
        t."calendar_month_number"     AS month_num,
        t."calendar_year"             AS year,
        SUM(s."amount_sold")          AS total_sales_eur
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"       s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"       t   ON s."time_id"   = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   c   ON s."cust_id"   = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   co  ON c."country_id"= co."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"  p   ON s."promo_id"  = p."promo_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"    ch  ON s."channel_id"= ch."channel_id"
    WHERE co."country_name" = 'France'
      AND p."promo_total_id"   = 1            -- only required promotions
      AND ch."channel_total_id"= 1            -- only required channels
      AND t."calendar_year" IN (2019, 2020)   -- history years
    GROUP BY
        s."prod_id",
        t."calendar_month_number",
        t."calendar_year"
),
prod_month_sales AS (  -- 2.  put 2019 & 2020 side-by-side
    SELECT
        "prod_id",
        month_num,
        MAX(CASE WHEN year = 2019 THEN total_sales_eur END) AS sales_2019,
        MAX(CASE WHEN year = 2020 THEN total_sales_eur END) AS sales_2020
    FROM fr_sales
    GROUP BY
        "prod_id",
        month_num
),
projections AS (       -- 3.  project 2021 sales in EUR
    SELECT
        "prod_id",
        month_num,
        CASE
           WHEN sales_2020 IS NULL                                THEN NULL                -- no 2020 data
           WHEN sales_2019 IS NULL OR sales_2019 = 0              THEN sales_2020          -- no 2019 baseline
           ELSE ((sales_2020 - sales_2019) / sales_2019) * sales_2020 + sales_2020
        END AS projected_2021_eur
    FROM prod_month_sales
),
conv AS (              -- 4.  2021 EUR->USD rates for France (default 1 if missing)
    SELECT
        "month"                           AS month_num,
        COALESCE("to_us", 1)              AS to_us_rate
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY"
    WHERE "country" = 'France'
      AND "year"    = 2021
)
-- 5.  average projected 2021 sales per month in USD
SELECT
    pr.month_num                                          AS "month_number",
    ROUND(AVG(pr.projected_2021_eur * COALESCE(cv.to_us_rate,1)), 2)
                                                         AS "avg_projected_sales_usd"
FROM projections pr
LEFT JOIN conv cv
       ON pr.month_num = cv.month_num
WHERE pr.projected_2021_eur IS NOT NULL
GROUP BY
    pr.month_num
ORDER BY
    pr.month_num;