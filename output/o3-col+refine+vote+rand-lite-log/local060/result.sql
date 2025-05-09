WITH us_sales AS (               -- ❶  keep only U-S sales rows
     SELECT s.*
     FROM   "sales"      AS s
     JOIN   "customers"  AS c  ON s."cust_id"  = c."cust_id"
     JOIN   "countries"  AS cn ON c."country_id" = cn."country_id"
     WHERE  cn."country_name" LIKE 'United States%'      -- United States of …
),
growth_cities AS (               -- ❷  U-S cities whose Q4-2020 sales ≥120 % of Q4-2019
     SELECT c."cust_city"
     FROM   us_sales  AS s
     JOIN   "customers" AS c ON s."cust_id" = c."cust_id"
     JOIN   "times"     AS t ON s."time_id" = t."time_id"
     WHERE  t."calendar_quarter_number" = 4
       AND  t."calendar_year" IN (2019, 2020)
       AND  s."promo_id" = 999                        -- “NO PROMOTION”
     GROUP  BY c."cust_city"
     HAVING SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" END) >=
            1.2 * SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" END)
),
top_products AS (                -- ❸  rank products within the growth cities, keep top 20 %
     SELECT "prod_id"
     FROM (
          SELECT s."prod_id",
                 SUM(s."amount_sold")                                         AS tot,
                 ROW_NUMBER() OVER (ORDER BY SUM(s."amount_sold") DESC)       AS rn,
                 COUNT(*)     OVER ()                                         AS cnt
          FROM   us_sales  AS s
          JOIN   "customers" AS c ON s."cust_id" = c."cust_id"
          JOIN   "times"     AS t ON s."time_id" = t."time_id"
          WHERE  t."calendar_quarter_number" = 4
            AND  t."calendar_year" IN (2019, 2020)
            AND  s."promo_id" = 999
            AND  c."cust_city" IN (SELECT "cust_city" FROM growth_cities)
          GROUP  BY s."prod_id"
     )
     WHERE rn <= 0.2 * cnt                         -- top-20 %
),
year_totals AS (                 -- ❹  total Q4 sales (all products) in the growth cities
     SELECT
            SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" END) AS total_2019,
            SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" END) AS total_2020
     FROM   us_sales  AS s
     JOIN   "customers" AS c ON s."cust_id" = c."cust_id"
     JOIN   "times"     AS t ON s."time_id" = t."time_id"
     WHERE  t."calendar_quarter_number" = 4
       AND  t."calendar_year" IN (2019, 2020)
       AND  s."promo_id" = 999
       AND  c."cust_city" IN (SELECT "cust_city" FROM growth_cities)
),
shares AS (                      -- ❺  sales of each top product in the two quarters
     SELECT tp."prod_id",
            SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" END) AS sales_2019,
            SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" END) AS sales_2020
     FROM   top_products AS tp
     JOIN   us_sales     AS s  ON s."prod_id" = tp."prod_id"
     JOIN   "customers"  AS c  ON s."cust_id" = c."cust_id"
     JOIN   "times"      AS t  ON s."time_id" = t."time_id"
     WHERE  t."calendar_quarter_number" = 4
       AND  t."calendar_year" IN (2019, 2020)
       AND  s."promo_id" = 999
       AND  c."cust_city" IN (SELECT "cust_city" FROM growth_cities)
     GROUP  BY tp."prod_id"
)
SELECT sh."prod_id",
       ROUND(1.0 * sh.sales_2019 / (SELECT total_2019 FROM year_totals), 4) AS share_2019,
       ROUND(1.0 * sh.sales_2020 / (SELECT total_2020 FROM year_totals), 4) AS share_2020,
       ROUND(1.0 * sh.sales_2020 / (SELECT total_2020 FROM year_totals) -
             1.0 * sh.sales_2019 / (SELECT total_2019 FROM year_totals), 4) AS share_change
FROM   shares AS sh
ORDER  BY share_change DESC;