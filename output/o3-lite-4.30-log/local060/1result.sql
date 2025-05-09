WITH us_customers AS (                 -- U.S. customers
    SELECT c.cust_id,
           c.cust_city
    FROM   customers  c
    JOIN   countries  co ON co.country_id = c.country_id
    WHERE  co.country_iso_code = 'US'
),
sales_q4 AS (                          -- Q4‑2019 & Q4‑2020 sales without promotions
    SELECT s.prod_id,
           uc.cust_city,
           t.calendar_year,
           s.amount_sold
    FROM   sales  s
    JOIN   us_customers uc ON uc.cust_id = s.cust_id
    JOIN   times  t        ON t.time_id  = s.time_id
    WHERE  t.calendar_year IN (2019, 2020)
      AND  t.calendar_quarter_number = 4
      AND  s.promo_id = 999                -- “NO PROMOTION”
),
city_totals AS (                        -- yearly totals per city
    SELECT cust_city,
           calendar_year,
           SUM(amount_sold) AS city_amt
    FROM   sales_q4
    GROUP  BY cust_city, calendar_year
),
growth_cities AS (                      -- cities whose 2020 ≥ 120 % of 2019
    SELECT c19.cust_city
    FROM   city_totals c19
    JOIN   city_totals c20
           ON c20.cust_city     = c19.cust_city
          AND c19.calendar_year = 2019
          AND c20.calendar_year = 2020
    WHERE  c20.city_amt >= 1.2 * c19.city_amt
),
filtered_sales AS (                     -- keep only growth‑city records
    SELECT sq.*
    FROM   sales_q4 sq
    JOIN   growth_cities gc ON gc.cust_city = sq.cust_city
),
product_year_amt AS (                   -- sales per product & year
    SELECT prod_id,
           calendar_year,
           SUM(amount_sold) AS amt
    FROM   filtered_sales
    GROUP  BY prod_id, calendar_year
),
year_totals AS (                        -- total sales (all products) per year
    SELECT calendar_year,
           SUM(amt) AS tot_amt
    FROM   product_year_amt
    GROUP  BY calendar_year
),
product_overall AS (                    -- overall amount 2019+2020 per product
    SELECT prod_id,
           SUM(amt) AS overall_amt
    FROM   product_year_amt
    GROUP  BY prod_id
),
ranked AS (                             -- divide into 5 buckets (20 % each)
    SELECT prod_id,
           NTILE(5) OVER (ORDER BY overall_amt DESC) AS quintile
    FROM   product_overall
),
top_products AS (                       -- take top 20 %
    SELECT prod_id
    FROM   ranked
    WHERE  quintile = 1
),
shares AS (                             -- amounts per top product per year
    SELECT tp.prod_id,
           COALESCE(SUM(CASE WHEN pya.calendar_year = 2019 THEN pya.amt END), 0) AS amt_2019,
           COALESCE(SUM(CASE WHEN pya.calendar_year = 2020 THEN pya.amt END), 0) AS amt_2020
    FROM   top_products tp
    JOIN   product_year_amt pya ON pya.prod_id = tp.prod_id
    GROUP  BY tp.prod_id
),
final AS (                              -- compute shares and their change
    SELECT pr.prod_name                                                  AS product,
           ROUND( amt_2020 * 1.0 / (SELECT tot_amt FROM year_totals WHERE calendar_year = 2020)
                - amt_2019 * 1.0 / (SELECT tot_amt FROM year_totals WHERE calendar_year = 2019), 4) AS share_change,
           ROUND( amt_2019 * 1.0 / (SELECT tot_amt FROM year_totals WHERE calendar_year = 2019), 4)  AS share_q4_2019,
           ROUND( amt_2020 * 1.0 / (SELECT tot_amt FROM year_totals WHERE calendar_year = 2020), 4)  AS share_q4_2020
    FROM   shares
    JOIN   products pr ON pr.prod_id = shares.prod_id
)
SELECT product,
       share_change,
       share_q4_2019,
       share_q4_2020
FROM   final
ORDER BY share_change DESC,
         product;