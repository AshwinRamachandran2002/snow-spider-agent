WITH sales_fr AS (   /* 1. France sales in 2019-2020 with required promos & channels */
    SELECT
        s."prod_id"                                            AS prod_id ,
        t."calendar_month_number"                              AS month ,
        t."calendar_year"                                      AS year ,
        SUM(s."amount_sold")                                   AS sales_amount
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES       s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS   c   ON s."cust_id"   = c."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES   co  ON c."country_id" = co."country_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.PROMOTIONS  p   ON s."promo_id"  = p."promo_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CHANNELS    ch  ON s."channel_id" = ch."channel_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES       t   ON s."time_id"   = t."time_id"
    WHERE  co."country_name"   = 'France'
      AND  p."promo_total_id"  = 1
      AND  ch."channel_total_id" = 1
      AND  t."calendar_year"  IN (2019 , 2020)
    GROUP BY
        s."prod_id",
        t."calendar_year",
        t."calendar_month_number"
),
pivot_sales AS (      /* 2. bring 2019 & 2020 side-by-side */
    SELECT
        prod_id ,
        month ,
        SUM(CASE WHEN year = 2019 THEN sales_amount END) AS sales_2019 ,
        SUM(CASE WHEN year = 2020 THEN sales_amount END) AS sales_2020
    FROM   sales_fr
    GROUP BY
        prod_id ,
        month
),
projected AS (        /* 3. project 2021 sales with given formula */
    SELECT
        prod_id ,
        month ,
        CASE
            WHEN sales_2019 IS NOT NULL
             AND sales_2019 <> 0
             AND sales_2020 IS NOT NULL
            THEN ((sales_2020 - sales_2019) / sales_2019) * sales_2020 + sales_2020
        END                                              AS projected_sales_2021
    FROM   pivot_sales
),
projected_usd AS (    /* 4. convert 2021 projection to USD via 2021 FX rates */
    SELECT
        pr.month                                                            AS month ,
        pr.projected_sales_2021 * COALESCE(cur."to_us" , 1)                 AS projected_sales_usd
    FROM   projected                         pr
    LEFT  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CURRENCY  cur
           ON  cur."country" = 'France'
           AND cur."year"    = 2021
           AND cur."month"   = pr.month
    WHERE  pr.projected_sales_2021 IS NOT NULL
)
SELECT                                          /* 5. average monthly projection */
    month ,
    ROUND(AVG(projected_sales_usd), 4)  AS average_projected_sales_usd
FROM   projected_usd
GROUP BY month
ORDER BY month;