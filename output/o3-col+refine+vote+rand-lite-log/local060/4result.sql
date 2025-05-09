WITH
/* -----------------------------------------------------------
   1)  United-States key
----------------------------------------------------------- */
country_us AS (
    SELECT country_id
    FROM   countries
    WHERE  country_name = 'United States of America'
),

/* -----------------------------------------------------------
   2)  Q4-2019 & Q4-2020 totals per city (no-promo)
----------------------------------------------------------- */
q19 AS (
    SELECT c.cust_city,
           SUM(s.amount_sold) AS amt19
    FROM   sales      s
    JOIN   customers  c ON s.cust_id = c.cust_id
    JOIN   times      t ON s.time_id = t.time_id
    WHERE  c.country_id = (SELECT country_id FROM country_us)
      AND  t.calendar_quarter_desc = '2019-04'      -- Q4-2019
      AND  s.promo_id            = 999              -- no promotion
    GROUP  BY c.cust_city
),
q20 AS (
    SELECT c.cust_city,
           SUM(s.amount_sold) AS amt20
    FROM   sales      s
    JOIN   customers  c ON s.cust_id = c.cust_id
    JOIN   times      t ON s.time_id = t.time_id
    WHERE  c.country_id = (SELECT country_id FROM country_us)
      AND  t.calendar_quarter_desc = '2020-04'      -- Q4-2020
      AND  s.promo_id            = 999
    GROUP  BY c.cust_city
),

/* -----------------------------------------------------------
   3)  Cities whose sales grew ≥20 %
----------------------------------------------------------- */
fast_cities AS (
    SELECT q19.cust_city
    FROM   q19
    JOIN   q20 USING (cust_city)
    WHERE  (q20.amt20 - q19.amt19) * 1.0 / q19.amt19 >= 0.20
),

/* -----------------------------------------------------------
   4)  Rank products by total Q4-2019+2020 sales
----------------------------------------------------------- */
prod_tot AS (
    SELECT s.prod_id,
           SUM(s.amount_sold) AS tot_amt
    FROM   sales     s
    JOIN   customers c ON s.cust_id = c.cust_id
    JOIN   times     t ON s.time_id = t.time_id
    WHERE  c.cust_city IN (SELECT cust_city FROM fast_cities)
      AND  t.calendar_quarter_desc IN ('2019-04','2020-04')
      AND  s.promo_id = 999
    GROUP  BY s.prod_id
),
top_prod AS (      -- keep top 20 % of those products
    SELECT prod_id
    FROM (
        SELECT prod_id,
               tot_amt,
               ROW_NUMBER() OVER (ORDER BY tot_amt DESC) AS rn,
               COUNT(*)  OVER ()                        AS cnt
        FROM   prod_tot
    )
    WHERE rn <= cnt * 0.20
),

/* -----------------------------------------------------------
   5)  Sales per (top) product & year
----------------------------------------------------------- */
quarter_prod AS (
    SELECT s.prod_id,
           t.calendar_year      AS yr,
           SUM(s.amount_sold)   AS prod_amt
    FROM   sales     s
    JOIN   customers c ON s.cust_id = c.cust_id
    JOIN   times     t ON s.time_id = t.time_id
    WHERE  s.prod_id IN (SELECT prod_id FROM top_prod)
      AND  c.cust_city IN (SELECT cust_city FROM fast_cities)
      AND  t.calendar_quarter_desc IN ('2019-04','2020-04')
      AND  s.promo_id = 999
    GROUP  BY s.prod_id, t.calendar_year
),

/* -----------------------------------------------------------
   6)  City-wide totals per year (for the denominator)
----------------------------------------------------------- */
quarter_tot AS (
    SELECT t.calendar_year AS yr,
           SUM(s.amount_sold) AS tot_amt
    FROM   sales     s
    JOIN   customers c ON s.cust_id = c.cust_id
    JOIN   times     t ON s.time_id = t.time_id
    WHERE  c.cust_city IN (SELECT cust_city FROM fast_cities)
      AND  t.calendar_quarter_desc IN ('2019-04','2020-04')
      AND  s.promo_id = 999
    GROUP  BY t.calendar_year
),

/* -----------------------------------------------------------
   7)  Shares & change in share
----------------------------------------------------------- */
prod_share AS (
    SELECT qp.prod_id,
           COALESCE(SUM(CASE WHEN yr = 2019 THEN prod_amt END),0)
                 / (SELECT tot_amt FROM quarter_tot WHERE yr = 2019) AS sh19,
           COALESCE(SUM(CASE WHEN yr = 2020 THEN prod_amt END),0)
                 / (SELECT tot_amt FROM quarter_tot WHERE yr = 2020) AS sh20
    FROM   quarter_prod qp
    GROUP  BY qp.prod_id
)

/* -----------------------------------------------------------
   8)  Final result
----------------------------------------------------------- */
SELECT prod_id,
       ROUND(100.0 * sh19, 2) AS share_2019_pct,
       ROUND(100.0 * sh20, 2) AS share_2020_pct,
       ROUND(100.0 * (sh20 - sh19), 2) AS share_change_pct
FROM   prod_share
ORDER  BY share_change_pct DESC;