WITH france_sales AS (   -- historical monthly sales (France, filtered promo/channel)
    SELECT
        s."prod_id",
        t."calendar_year"      AS yr,
        t."calendar_month_number" AS mn,
        SUM(s."amount_sold")   AS amt
    FROM
        COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"       s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   c  ON s."cust_id"   = c."cust_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   co ON c."country_id" = co."country_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS"  pr ON s."promo_id"  = pr."promo_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"    ch ON s."channel_id" = ch."channel_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"       t  ON s."time_id"   = t."time_id"
    WHERE
        co."country_name"   = 'France'
        AND pr."promo_total_id"   = 1
        AND ch."channel_total_id" = 1
        AND t."calendar_year" IN (2019,2020)
    GROUP BY
        s."prod_id", t."calendar_year", t."calendar_month_number"
),                                                         
pivoted AS (           -- align 2019 & 2020 numbers per product-month
    SELECT
        COALESCE(a."prod_id", b."prod_id")      AS prod_id,
        COALESCE(a.mn,        b.mn)             AS mn,
        COALESCE(b.amt,0)                       AS sales20,
        COALESCE(a.amt,0)                       AS sales19
    FROM france_sales a   -- 2020
    FULL OUTER JOIN france_sales b   -- 2019
         ON a."prod_id"            = b."prod_id"
        AND a.mn                   = b.mn
        AND a.yr                   = 2020
        AND b.yr                   = 2019
    WHERE a.yr = 2020 OR b.yr = 2019
),                                                         
proj_2021 AS (         -- apply growth formula
    SELECT
        prod_id,
        mn,
        CASE 
            WHEN sales19 <> 0
                 THEN ((sales20 - sales19) / sales19) * sales20 + sales20
            ELSE sales20
        END AS proj_sales
    FROM pivoted
),                                                         
proj_usd AS (          -- convert to USD & average per month
    SELECT
        p.mn,
        AVG( p.proj_sales * COALESCE(cur."to_us",1) ) AS avg_month_proj_usd
    FROM
        proj_2021               p
        LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cur
               ON cur."country" = 'France'
              AND cur."year"    = 2021
              AND cur."month"   = p.mn
    GROUP BY
        p.mn
)                      -- final median of the 12 monthly averages
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_month_proj_usd) 
           AS median_avg_monthly_projected_sales_usd_2021
FROM proj_usd;