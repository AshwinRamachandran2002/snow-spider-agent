WITH monthly_sales AS (
    /* Monthly sales (amount_sold) for France in 2019‑2020
       – only rows whose promotion & channel belong to the overall‑total groups            */
    SELECT
        s."prod_id",
        t."calendar_month_number"            AS month,
        t."calendar_year"                    AS year,
        SUM(s."amount_sold")                 AS total_sales
    FROM   "sales"      s
    JOIN   "promotions" p   ON s."promo_id"   = p."promo_id"
                           AND p."promo_total_id" = 1
    JOIN   "channels"   ch  ON s."channel_id" = ch."channel_id"
                           AND ch."channel_total_id" = 1
    JOIN   "customers"  c   ON s."cust_id"    = c."cust_id"
    JOIN   "countries"  co  ON c."country_id" = co."country_id"
                           AND co."country_name" = 'France'
    JOIN   "times"      t   ON s."time_id"    = t."time_id"
    WHERE  t."calendar_year" IN (2019, 2020)
    GROUP  BY s."prod_id", t."calendar_month_number", t."calendar_year"
),  
growth AS (
    /*  Growth factor from 2019 to 2020 for each product & month                        */
    SELECT
        y20."prod_id",
        y20."month",
        y19.total_sales                         AS sales_2019,
        y20.total_sales                         AS sales_2020,
        CASE WHEN y19.total_sales > 0
             THEN y20.total_sales * 1.0 / y19.total_sales
        END                                      AS growth_factor
    FROM   monthly_sales y20
    LEFT   JOIN monthly_sales y19
           ON  y20."prod_id" = y19."prod_id"
           AND y20."month"   = y19."month"
           AND y19."year"    = 2019
    WHERE  y20."year" = 2020
),  
projected_local AS (
    /* Project 2021 sales in local currency */
    SELECT
        "prod_id",
        "month",
        sales_2020 * growth_factor              AS projected_sales_local
    FROM   growth
    WHERE  growth_factor IS NOT NULL
),  
projected_usd AS (
    /* Convert 2021 projection to USD with 2021 FX rate                                 */
    SELECT
        pl."month",
        pl."prod_id",
        pl.projected_sales_local * cur."to_us"  AS projected_sales_usd
    FROM   projected_local  pl
    JOIN   "currency" cur
           ON  cur."country" = 'France'
           AND cur."year"    = 2021
           AND cur."month"   = pl."month"
)
SELECT
    "month",
    ROUND(AVG(projected_sales_usd), 4) AS avg_projected_sales_usd
FROM   projected_usd
GROUP  BY "month"
ORDER BY "month";