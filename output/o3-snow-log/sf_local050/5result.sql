/*  Median of the average monthly-projected 2021 sales (in USD) for France  */
WITH sale_usd AS (
    /* 1.  France sales (promo_total_id = 1, channel_total_id = 1) converted to USD */
    SELECT
        s."amount_sold" * COALESCE(cur."to_us", 1)             AS amount_usd,
        t."calendar_year",
        t."calendar_month_number"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"          s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"      cust ON s."cust_id"   = cust."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"      cnt  ON cust."country_id" = cnt."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"          t    ON s."time_id"   = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"     pr   ON s."promo_id"  = pr."promo_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"       ch   ON s."channel_id"= ch."channel_id"
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY"  cur
           ON cur."country" = 'France'
          AND cur."year"    = t."calendar_year"
          AND cur."month"   = t."calendar_month_number"
    WHERE cnt."country_name"  = 'France'
      AND pr."promo_total_id" = 1
      AND ch."channel_total_id" = 1
      AND t."calendar_year" IN (2019, 2020)
),
monthly_sales AS (
    /* 2.  Total sales per month for 2019 and 2020 (already in USD) */
    SELECT
        "calendar_year"                    AS yr,
        "calendar_month_number"            AS mn,
        SUM(amount_usd)                    AS sales_usd
    FROM sale_usd
    GROUP BY "calendar_year", "calendar_month_number"
),
m19 AS (SELECT mn, sales_usd FROM monthly_sales WHERE yr = 2019),
m20 AS (SELECT mn, sales_usd FROM monthly_sales WHERE yr = 2020),
projected_2021 AS (
    /* 3.  Project 2021 sales for each month using the 2019-2020 growth rate */
    SELECT
        m20.mn                                                    AS month,
        ((m20.sales_usd - m19.sales_usd) / NULLIF(m19.sales_usd,0))
        * m20.sales_usd + m20.sales_usd                           AS projected_sales_usd
    FROM m20
    JOIN m19 USING (mn)
)
SELECT
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY projected_sales_usd),
        2
    ) AS "MEDIAN_AVG_MONTHLY_PROJECTED_SALES_USD_2021"
FROM projected_2021;