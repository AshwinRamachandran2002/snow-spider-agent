WITH sales_us AS (
    /* Sales in the USA (iso‑code US or name beginning with 'United States') made under promo 999
       during Q4‑2019 (1772) and Q4‑2020 (1776) */
    SELECT  s.prod_id,
            s.cust_id,
            s.amount_sold,
            cu.cust_city,
            t.calendar_quarter_id
    FROM    sales      AS s
    JOIN    customers  AS cu ON cu.cust_id   = s.cust_id
    JOIN    countries  AS co ON co.country_id = cu.country_id
    JOIN    times      AS t  ON t.time_id    = s.time_id
    WHERE   (co.country_iso_code = 'US'
             OR co.country_name  LIKE 'United States%')
      AND   s.promo_id            = 999
      AND   t.calendar_quarter_id IN (1772,1776)          -- Q4‑2019 & Q4‑2020
),
/*  Cities whose sales grew by at least 20 % from Q4‑2019 to Q4‑2020             */
city_growth AS (
    SELECT  c19.cust_city
    FROM   (SELECT cust_city,
                   SUM(amount_sold) AS amt_19
            FROM   sales_us
            WHERE  calendar_quarter_id = 1772
            GROUP  BY cust_city) AS c19
    JOIN   (SELECT cust_city,
                   SUM(amount_sold) AS amt_20
            FROM   sales_us
            WHERE  calendar_quarter_id = 1776
            GROUP  BY cust_city) AS c20
           USING (cust_city)
    WHERE   c20.amt_20 >= 1.2 * c19.amt_19
),
/*  Keep only sales that happened in the growing cities                          */
filtered_sales AS (
    SELECT  *
    FROM    sales_us
    WHERE   cust_city IN (SELECT cust_city FROM city_growth)
),
/*  Product totals in each quarter                                               */
prod_qtr AS (
    SELECT  prod_id,
            calendar_quarter_id            AS qtr,
            SUM(amount_sold)               AS amt
    FROM    filtered_sales
    GROUP BY prod_id, qtr
),
/*  Grand totals per quarter                                                     */
tot_qtr AS (
    SELECT  qtr,
            SUM(amt)                       AS total_amt
    FROM    prod_qtr
    GROUP BY qtr
),
/*  Product share of total sales in each quarter                                 */
share_qtr AS (
    SELECT  p.prod_id,
            p.qtr,
            p.amt,
            1.0 * p.amt / t.total_amt      AS share
    FROM    prod_qtr p
    JOIN    tot_qtr t USING (qtr)
),
/*  Pivot the two quarters side‑by‑side                                          */
share_pivot AS (
    SELECT  prod_id,
            MAX(CASE WHEN qtr = 1772 THEN share END)          AS share_2019,
            MAX(CASE WHEN qtr = 1776 THEN share END)          AS share_2020,
            SUM(amt)                                          AS total_amt_both
    FROM    share_qtr
    GROUP BY prod_id
),
/*  Rank products by total sales, keep top 20 %                                  */
ranked AS (
    SELECT  *,
            NTILE(5) OVER (ORDER BY total_amt_both DESC)      AS bucket,
            ABS(COALESCE(share_2020,0) - COALESCE(share_2019,0)) AS abs_change
    FROM    share_pivot
)
SELECT  pr.prod_id,
        pr.prod_name,
        ranked.share_2019,
        ranked.share_2020,
        ranked.abs_change
FROM    ranked
JOIN    products pr ON pr.prod_id = ranked.prod_id
WHERE   ranked.bucket = 1                 -- top 20 %
ORDER   BY ranked.abs_change ASC,
         pr.prod_id
LIMIT 1;