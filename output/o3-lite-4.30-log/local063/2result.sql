WITH
-- Q4‑2019 promo‑999 sales per U.S. city
q19 AS (
    SELECT cu."cust_city"                       AS city,
           SUM(s."amount_sold")                 AS amt19
    FROM   "sales"      s
    JOIN   "times"      t  ON s."time_id"   = t."time_id"
    JOIN   "customers"  cu ON s."cust_id"   = cu."cust_id"
    JOIN   "countries"  co ON cu."country_id" = co."country_id"
    WHERE  co."country_iso_code" = 'US'
      AND  s."promo_id"            = 999
      AND  t."calendar_quarter_id" = 1772         -- Q4‑2019
    GROUP  BY cu."cust_city"
),
-- Q4‑2020 promo‑999 sales per U.S. city
q20 AS (
    SELECT cu."cust_city"                       AS city,
           SUM(s."amount_sold")                 AS amt20
    FROM   "sales"      s
    JOIN   "times"      t  ON s."time_id"   = t."time_id"
    JOIN   "customers"  cu ON s."cust_id"   = cu."cust_id"
    JOIN   "countries"  co ON cu."country_id" = co."country_id"
    WHERE  co."country_iso_code" = 'US'
      AND  s."promo_id"            = 999
      AND  t."calendar_quarter_id" = 1776         -- Q4‑2020
    GROUP  BY cu."cust_city"
),
-- Cities whose Q4‑2020 amount is at least 120 % of Q4‑2019
good_cities AS (
    SELECT q19.city
    FROM   q19
    JOIN   q20 ON q19.city = q20.city
    WHERE  q20.amt20 >= 1.20 * q19.amt19
),
-- Promo‑999 sales for those cities (both quarters)
sales_scope AS (
    SELECT p."prod_id",
           t."calendar_quarter_id"              AS qtr,
           SUM(s."amount_sold")                 AS amt
    FROM   "sales"      s
    JOIN   "times"      t  ON s."time_id"   = t."time_id"
    JOIN   "customers"  cu ON s."cust_id"   = cu."cust_id"
    JOIN   good_cities  gc ON cu."cust_city" = gc.city
    JOIN   "products"   p  ON s."prod_id"    = p."prod_id"
    WHERE  s."promo_id"            = 999
      AND  t."calendar_quarter_id" IN (1772,1776)
    GROUP  BY p."prod_id", t."calendar_quarter_id"
),
-- Total promo‑999 amount per quarter (growth cities only)
totals AS (
    SELECT qtr,
           SUM(amt)                            AS tot_amt
    FROM   sales_scope
    GROUP  BY qtr
),
-- Per‑product total and market share in each quarter
shares AS (
    SELECT s."prod_id",
           SUM(s.amt)                                                AS total_amt,
           COALESCE(SUM(CASE WHEN s.qtr = 1772 THEN s.amt END) /
                    NULLIF((SELECT tot_amt FROM totals WHERE qtr = 1772),0), 0) AS share19,
           COALESCE(SUM(CASE WHEN s.qtr = 1776 THEN s.amt END) /
                    NULLIF((SELECT tot_amt FROM totals WHERE qtr = 1776),0), 0) AS share20
    FROM   sales_scope s
    GROUP  BY s."prod_id"
),
-- Rank products by aggregate sales
ranked AS (
    SELECT sh.*,
           ROW_NUMBER() OVER (ORDER BY total_amt DESC) AS rn,
           COUNT(*)  OVER ()                           AS cnt
    FROM   shares sh
),
-- Keep the top 20 % of products (ceiling of cnt/5)
top20 AS (
    SELECT *
    FROM   ranked
    WHERE  rn <= ((cnt + 4) / 5)        -- integer “ceiling” of cnt/5
),
-- Product with the smallest absolute change in market share
final AS (
    SELECT "prod_id"                                                       AS product_id,
           ROUND((share20 - share19) * 100.0, 4) AS percentage_point_change_in_share_of_total_sales
    FROM   top20
    ORDER  BY ABS(share20 - share19)
    LIMIT  1
)
SELECT product_id,
       percentage_point_change_in_share_of_total_sales
FROM   final;