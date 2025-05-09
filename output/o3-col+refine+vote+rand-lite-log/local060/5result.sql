WITH
-- 1.  U.S. no-promotion sales for Q4-2019 and Q4-2020
us_sales AS (
    SELECT  s."prod_id",
            cu."cust_city"                        AS city,
            t."calendar_year"                    AS yr,
            s."amount_sold"
    FROM    "sales"      AS s
    JOIN    "customers"  AS cu  ON cu."cust_id"   = s."cust_id"
    JOIN    "countries"  AS co  ON co."country_id"= cu."country_id"
    JOIN    "times"      AS t   ON t."time_id"    = s."time_id"
    WHERE   co."country_name"  LIKE '%United States%'   -- U.S. only
      AND   s."promo_id"        = 999                   -- no promotion
      AND   t."calendar_quarter_number" = 4             -- Q4
      AND   t."calendar_year"  IN (2019,2020)
),

-- 2.  Total Q4 sales per city & year
city_totals AS (
    SELECT  city,
            yr,
            SUM("amount_sold") AS tot_sales
    FROM    us_sales
    GROUP BY city, yr
),

-- 3.  Keep cities whose Q4-2020 sales ≥ 120 % of Q4-2019
city_growth AS (
    SELECT  c19.city
    FROM    city_totals  c19
    JOIN    city_totals  c20
           ON c20.city = c19.city
          AND c19.yr   = 2019
          AND c20.yr   = 2020
    WHERE   c20.tot_sales >= 1.2 * c19.tot_sales
),

-- 4.  Sales restricted to the growing cities
filtered_sales AS (
    SELECT  *
    FROM    us_sales
    WHERE   city IN (SELECT city FROM city_growth)
),

-- 5.  Overall product sales (both Q4s, growing cities only)
product_totals AS (
    SELECT  "prod_id",
            SUM("amount_sold") AS tot_sales
    FROM    filtered_sales
    GROUP BY "prod_id"
),

-- 6.  Rank products and keep the top 20 %
product_rank AS (
    SELECT  "prod_id",
            tot_sales,
            CUME_DIST() OVER (ORDER BY tot_sales DESC) AS cum_pct
    FROM    product_totals
),
top_products AS (
    SELECT  "prod_id"
    FROM    product_rank
    WHERE   cum_pct <= 0.20          -- top 20 %
),

-- 7.  Product-level sales per year (top products only)
product_qtr_sales AS (
    SELECT  fs."prod_id",
            fs.yr,
            SUM(fs."amount_sold") AS qtr_sales
    FROM    filtered_sales fs
    WHERE   fs."prod_id" IN (SELECT "prod_id" FROM top_products)
    GROUP BY fs."prod_id", fs.yr
),

-- 8.  Total (all-product) sales per year for the growing cities
totals_by_year AS (
    SELECT  yr,
            SUM("amount_sold") AS yr_total
    FROM    filtered_sales
    GROUP BY yr
),

-- 9.  Pivot product sales into 2019 vs 2020 columns
final AS (
    SELECT  tp."prod_id",
            pr."prod_name",
            COALESCE(SUM(CASE WHEN pqs.yr = 2019 THEN pqs.qtr_sales END),0) AS sales_2019,
            COALESCE(SUM(CASE WHEN pqs.yr = 2020 THEN pqs.qtr_sales END),0) AS sales_2020
    FROM    top_products tp
    LEFT JOIN product_qtr_sales pqs ON pqs."prod_id" = tp."prod_id"
    LEFT JOIN "products"      pr    ON pr."prod_id"  = tp."prod_id"
    GROUP BY tp."prod_id"
),

-- 10.  Compute shares and share change
shares AS (
    SELECT  f."prod_id",
            f."prod_name",
            ROUND(f.sales_2019 * 1.0 /
                  (SELECT yr_total FROM totals_by_year WHERE yr = 2019),4) AS share_2019,
            ROUND(f.sales_2020 * 1.0 /
                  (SELECT yr_total FROM totals_by_year WHERE yr = 2020),4) AS share_2020
    FROM    final f
)

SELECT  "prod_id",
        "prod_name",
        share_2019,
        share_2020,
        ROUND(share_2020 - share_2019,4) AS share_change
FROM    shares
ORDER BY share_change DESC;