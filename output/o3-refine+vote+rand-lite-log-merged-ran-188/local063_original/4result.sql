WITH
/* 1. All U.S. sales with promo_id = 999 during Q4‑2019 & Q4‑2020 */
us_sales AS (
    SELECT  s.prod_id,
            c.cust_city,
            t.calendar_quarter_id AS quarter_id,
            s.amount_sold
    FROM    sales      AS s
    JOIN    times      AS t  ON t.time_id     = s.time_id
    JOIN    customers  AS c  ON c.cust_id     = s.cust_id
    JOIN    countries  AS co ON co.country_id = c.country_id
    WHERE   s.promo_id              = 999
      AND   co.country_name         = 'United States of America'
      AND   t.calendar_quarter_id IN (1772,1776)      -- Q4‑2019 & Q4‑2020
),

/* 2. Quarterly totals per city */
city_quarter AS (
    SELECT  cust_city AS city,
            quarter_id,
            SUM(amount_sold) AS city_sales
    FROM    us_sales
    GROUP BY cust_city, quarter_id
),

/* 3. Cities whose sales grew ≥ 20 % between the two quarters */
city_growth AS (
    SELECT  c19.city
    FROM    city_quarter c19
    JOIN    city_quarter c20
           ON c20.city = c19.city
          AND c19.quarter_id = 1772          -- Q4‑2019
          AND c20.quarter_id = 1776          -- Q4‑2020
    WHERE   c20.city_sales >= c19.city_sales * 1.20
),

/* 4. Sales restricted to the growing cities */
eligible_sales AS (
    SELECT  s.prod_id,
            s.quarter_id,
            s.amount_sold
    FROM    us_sales s
    JOIN    city_growth g ON g.city = s.cust_city
),

/* 5. Product totals per quarter */
prod_quarter AS (
    SELECT  prod_id,
            quarter_id,
            SUM(amount_sold) AS prod_sales
    FROM    eligible_sales
    GROUP BY prod_id, quarter_id
),

/* 6. Total market size per quarter */
quarter_tot AS (
    SELECT  quarter_id,
            SUM(prod_sales) AS total_sales
    FROM    prod_quarter
    GROUP BY quarter_id
),

/* 7. Market share of every product in each quarter */
prod_share AS (
    SELECT  p.prod_id,
            p.quarter_id,
            p.prod_sales,
            1.0 * p.prod_sales / q.total_sales AS share
    FROM    prod_quarter p
    JOIN    quarter_tot  q USING (quarter_id)
),

/* 8. Share change and combined sales volume */
prod_change AS (
    SELECT  s19.prod_id,
            s19.share            AS share_2019,
            s20.share            AS share_2020,
            ABS(s20.share - s19.share) AS share_change,
            s19.prod_sales + s20.prod_sales AS total_sales_both
    FROM    prod_share s19
    JOIN    prod_share s20
           ON s20.prod_id = s19.prod_id
          AND s19.quarter_id = 1772
          AND s20.quarter_id = 1776
),

/* 9. Split products into 5 buckets by total sales; keep top 20 % (bucket 1) */
ranked AS (
    SELECT  pc.*,
            NTILE(5) OVER (ORDER BY total_sales_both DESC) AS bucket
    FROM    prod_change pc
),
top_20 AS (
    SELECT *
    FROM   ranked
    WHERE  bucket = 1
)

/* 10. Product in top 20 % with the smallest share‑change */
SELECT  t.prod_id,
        pr.prod_name,
        t.share_2019,
        t.share_2020,
        t.share_change
FROM    top_20 t
JOIN    products pr ON pr.prod_id = t.prod_id
ORDER BY t.share_change ASC, t.prod_id
LIMIT 1;