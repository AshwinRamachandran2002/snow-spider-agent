WITH
/* --- Q4 2019 and Q4 2020 calendar rows --- */
time_qtr AS (
    SELECT time_id,
           calendar_year AS yr
    FROM   times
    WHERE  (calendar_year = 2019 AND calendar_quarter_number = 4)
        OR (calendar_year = 2020 AND calendar_quarter_number = 4)
),

/* --- U.S. sales made WITHOUT a promotion (promo_id = 999 means “no promotion”) --- */
us_sales AS (
    SELECT  s.amount_sold,
            s.prod_id,
            s.cust_id,
            tq.yr,
            cu.cust_city
    FROM    sales      AS s
    JOIN    time_qtr   AS tq ON s.time_id = tq.time_id
    JOIN    customers  AS cu ON s.cust_id = cu.cust_id
    JOIN    countries  AS co ON cu.country_id = co.country_id
    WHERE   co.country_iso_code = 'US'
      AND   s.promo_id = 999
),

/* --- city totals for each of the two quarters --- */
city_qtr_sales AS (
    SELECT  cust_city AS city,
            yr,
            SUM(amount_sold) AS total_sales
    FROM    us_sales
    GROUP BY cust_city, yr
),

/* --- cities whose Q4‑2020 sales ≥ 120 % of Q4‑2019 sales --- */
city_growth AS (
    SELECT  c19.city
    FROM    city_qtr_sales c19
    JOIN    city_qtr_sales c20
           ON c19.city = c20.city
          AND c19.yr   = 2019
          AND c20.yr   = 2020
    WHERE   c19.total_sales > 0
      AND   c20.total_sales >= 1.2 * c19.total_sales
),

/* --- keep only sales that happened in the “growing” cities --- */
filtered_sales AS (
    SELECT *
    FROM   us_sales
    WHERE  cust_city IN (SELECT city FROM city_growth)
),

/* --- overall amount per product across both years in those cities --- */
product_totals AS (
    SELECT  prod_id,
            SUM(amount_sold) AS total_amt
    FROM    filtered_sales
    GROUP BY prod_id
),

/* --- rank products and keep the top 20 % (bucket = 1 out of 5) --- */
ranked_products AS (
    SELECT  prod_id,
            NTILE(5) OVER (ORDER BY total_amt DESC) AS bucket
    FROM    product_totals
),
top_products AS (
    SELECT  prod_id
    FROM    ranked_products
    WHERE   bucket = 1
),

/* --- year totals for those top products --- */
product_qtr_sales AS (
    SELECT  fs.prod_id,
            fs.yr,
            SUM(fs.amount_sold) AS amt
    FROM    filtered_sales fs
    WHERE   fs.prod_id IN (SELECT prod_id FROM top_products)
    GROUP BY fs.prod_id, fs.yr
),

/* --- grand total (all products) for each year in the same city set --- */
total_qtr_sales AS (
    SELECT yr,
           SUM(amount_sold) AS total_amt
    FROM   filtered_sales
    GROUP BY yr
),

/* --- compute share of each top product in each year --- */
product_shares AS (
    SELECT  pqs.prod_id,
            pqs.yr,
            1.0 * pqs.amt / tqs.total_amt AS share
    FROM    product_qtr_sales pqs
    JOIN    total_qtr_sales  tqs ON pqs.yr = tqs.yr
),

/* --- pivot to have both years on the same row --- */
share_pivot AS (
    SELECT prod_id,
           MAX(CASE WHEN yr = 2019 THEN share END) AS share_2019,
           MAX(CASE WHEN yr = 2020 THEN share END) AS share_2020
    FROM   product_shares
    GROUP BY prod_id
)

SELECT  prod_id,
        ROUND(COALESCE(share_2019,0),4) AS share_2019,
        ROUND(COALESCE(share_2020,0),4) AS share_2020,
        ROUND(COALESCE(share_2020,0) - COALESCE(share_2019,0),4) AS share_change
FROM    share_pivot
ORDER BY share_change DESC,
         prod_id;