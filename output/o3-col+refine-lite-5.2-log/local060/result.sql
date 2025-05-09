/*  ─────────────────────────────────────────────────────────────────────────────
    United States – Q4‑2019 vs Q4‑2020 (no‑promotion)
    1. keep only cities whose total sales grew ≥20 %
    2. rank products inside those cities by combined Q4‑2019+Q4‑2020 sales;
       keep the top 20 %
    3. for every kept product, show its share of total sales in each quarter
       and the change in share, ordered by the change (descending)
    ─────────────────────────────────────────────────────────────────────────── */
WITH
/* ── city‑level totals ─────────────────────────────────────────────────────── */
q4_19 AS (   -- 2019‑Q4 totals per city
    SELECT  cu."cust_city"            AS city,
            SUM(s."amount_sold")      AS sales19
    FROM    "sales"      s
    JOIN    "customers"  cu ON cu."cust_id"   = s."cust_id"
    JOIN    "countries"  co ON co."country_id"= cu."country_id"
    JOIN    "times"      t  ON t."time_id"    = s."time_id"
    WHERE   co."country_name"      = 'United States of America'
      AND   t."calendar_year"      = 2019
      AND   t."calendar_quarter_number" = 4
      AND   s."promo_id"           = 999          -- no promotion
    GROUP BY cu."cust_city"
),
q4_20 AS (   -- 2020‑Q4 totals per city
    SELECT  cu."cust_city"            AS city,
            SUM(s."amount_sold")      AS sales20
    FROM    "sales"      s
    JOIN    "customers"  cu ON cu."cust_id"   = s."cust_id"
    JOIN    "countries"  co ON co."country_id"= cu."country_id"
    JOIN    "times"      t  ON t."time_id"    = s."time_id"
    WHERE   co."country_name"      = 'United States of America'
      AND   t."calendar_year"      = 2020
      AND   t."calendar_quarter_number" = 4
      AND   s."promo_id"           = 999
    GROUP BY cu."cust_city"
),
/* ── cities with ≥20 % growth ──────────────────────────────────────────────── */
growing_cities AS (
    SELECT q20.city
    FROM   q4_19 q19
    JOIN   q4_20 q20  ON q19.city = q20.city
    WHERE  q20.sales20 >= 1.20 * q19.sales19
),
/* ── product‑level sales inside the growing cities ─────────────────────────── */
prod_sales AS (
    SELECT  s."prod_id",
            SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END) AS sales19,
            SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" ELSE 0 END) AS sales20
    FROM    "sales"      s
    JOIN    "customers"  cu ON cu."cust_id"    = s."cust_id"
    JOIN    growing_cities gc ON gc.city       = cu."cust_city"
    JOIN    "countries"  co ON co."country_id" = cu."country_id"
    JOIN    "times"      t  ON t."time_id"     = s."time_id"
    WHERE   co."country_name"  = 'United States of America'
      AND   t."calendar_year" IN (2019, 2020)
      AND   t."calendar_quarter_number" = 4
      AND   s."promo_id"     = 999
    GROUP BY s."prod_id"
),
/* ── rank products & keep the top 20 % by combined sales ───────────────────── */
ranked AS (
    SELECT  ps.*,
            (ps.sales19 + ps.sales20)                    AS total_sales,
            ROW_NUMBER() OVER (ORDER BY (ps.sales19 + ps.sales20) DESC) AS rn,
            COUNT(*)  OVER ()                            AS cnt
    FROM    prod_sales ps
),
top20 AS (
    SELECT * FROM ranked
    WHERE  rn <= 0.20 * cnt
),
/* ── overall denominators for market‑share calculation ─────────────────────── */
totals AS (
    SELECT  SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END) AS tot19,
            SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" ELSE 0 END) AS tot20
    FROM    "sales"      s
    JOIN    "customers"  cu ON cu."cust_id"    = s."cust_id"
    JOIN    growing_cities gc ON gc.city       = cu."cust_city"
    JOIN    "countries"  co ON co."country_id" = cu."country_id"
    JOIN    "times"      t  ON t."time_id"     = s."time_id"
    WHERE   co."country_name"  = 'United States of America'
      AND   t."calendar_year" IN (2019, 2020)
      AND   t."calendar_quarter_number" = 4
      AND   s."promo_id"     = 999
)
/* ── final output ───────────────────────────────────────────────────────────── */
SELECT  p."prod_name",
        ROUND( (t20.sales19 / tot.tot19) * 100.0 , 4)  AS share_2019_pct,
        ROUND( (t20.sales20 / tot.tot20) * 100.0 , 4)  AS share_2020_pct,
        ROUND( ((t20.sales20 / tot.tot20) - (t20.sales19 / tot.tot19)) * 100.0 , 4) AS share_change_pct
FROM    top20        t20
JOIN    "products"   p   ON p."prod_id" = t20."prod_id"
JOIN    totals       tot
ORDER BY share_change_pct DESC, p."prod_name";