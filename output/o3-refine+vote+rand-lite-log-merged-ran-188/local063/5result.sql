WITH qualified_cities AS (      -- Cities whose sales ↑ ≥20 % from Q4-2019 to Q4-2020
    SELECT q20.cust_city
    FROM (
        SELECT c.cust_city, SUM(s.amount_sold) AS amt_2019
        FROM   sales s
        JOIN   customers c ON c.cust_id = s.cust_id
        JOIN   times t     ON t.time_id = s.time_id
        WHERE  c.country_id IN (SELECT country_id
                                FROM countries
                                WHERE country_name LIKE '%United%States%')
          AND  s.promo_id            = 999
          AND  t.calendar_quarter_id = 1772              -- Q4-2019
        GROUP  BY c.cust_city
    ) AS q19
    JOIN (
        SELECT c.cust_city, SUM(s.amount_sold) AS amt_2020
        FROM   sales s
        JOIN   customers c ON c.cust_id = s.cust_id
        JOIN   times t     ON t.time_id = s.time_id
        WHERE  c.country_id IN (SELECT country_id
                                FROM countries
                                WHERE country_name LIKE '%United%States%')
          AND  s.promo_id            = 999
          AND  t.calendar_quarter_id = 1776              -- Q4-2020
        GROUP  BY c.cust_city
    ) AS q20 USING (cust_city)
    WHERE q20.amt_2020 >= 1.20 * q19.amt_2019
),
sales_by_prod_qtr AS (          -- Sales per product & quarter in those cities
    SELECT s.prod_id,
           t.calendar_quarter_id AS qtr_id,
           SUM(s.amount_sold)    AS amt
    FROM   sales s
    JOIN   customers c ON c.cust_id = s.cust_id
    JOIN   times     t ON t.time_id = s.time_id
    WHERE  c.cust_city IN (SELECT cust_city FROM qualified_cities)
      AND  c.country_id IN (SELECT country_id
                             FROM countries
                             WHERE country_name LIKE '%United%States%')
      AND  s.promo_id            = 999
      AND  t.calendar_quarter_id IN (1772,1776)
    GROUP  BY s.prod_id, t.calendar_quarter_id
),
tot_amt_per_prod AS (           -- Combined Q4-19 & Q4-20 totals per product
    SELECT prod_id, SUM(amt) AS total_amt
    FROM   sales_by_prod_qtr
    GROUP  BY prod_id
),
top_20pct AS (                  -- Products in the top 20 % of total sales
    SELECT prod_id
    FROM   tot_amt_per_prod
    ORDER  BY total_amt DESC
    LIMIT (SELECT CAST(0.2 * COUNT(*) AS INTEGER) FROM tot_amt_per_prod)
),
tot_amt_per_qtr AS (            -- Quarter totals (for share calc)
    SELECT qtr_id, SUM(amt) AS qtr_total
    FROM   sales_by_prod_qtr
    GROUP  BY qtr_id
),
shares AS (                     -- Share of each product within each quarter
    SELECT sb.prod_id,
           sb.qtr_id,
           100.0 * sb.amt / tq.qtr_total AS share_pct
    FROM   sales_by_prod_qtr sb
    JOIN   tot_amt_per_qtr  tq USING (qtr_id)
    WHERE  sb.prod_id IN (SELECT prod_id FROM top_20pct)
),
pivot AS (                      -- Put both quarters on one row & calc change
    SELECT s19.prod_id,
           s19.share_pct AS share_2019,
           s20.share_pct AS share_2020,
           s20.share_pct - s19.share_pct AS pct_pt_change
    FROM   shares s19
    JOIN   shares s20
           ON s20.prod_id = s19.prod_id
          AND s20.qtr_id  = 1776          -- Q4-2020
    WHERE  s19.qtr_id      = 1772         -- Q4-2019
)
SELECT prod_id,
       ROUND(share_2019,4)       AS share_2019_pct,
       ROUND(share_2020,4)       AS share_2020_pct,
       ROUND(pct_pt_change,4)    AS pct_point_change
FROM   pivot
ORDER  BY ABS(pct_pt_change)     -- smallest change first
LIMIT 1;