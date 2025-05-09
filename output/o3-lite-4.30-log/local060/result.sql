WITH us_q4_nopromo AS (
    /* U.S. Q4‑2019 & Q4‑2020 sales without promotions (promo_id = 999) */
    SELECT s.prod_id,
           s.cust_id,
           s.amount_sold,
           t.calendar_year,
           c.cust_city
    FROM   sales     s
    JOIN   times     t  ON s.time_id = t.time_id
    JOIN   customers c  ON s.cust_id = c.cust_id
    JOIN   countries co ON c.country_id = co.country_id
    WHERE  co.country_name = 'United States of America'
      AND  t.calendar_year IN (2019, 2020)
      AND  t.calendar_quarter_number = 4
      AND  s.promo_id = 999
),
growth_cities AS (
    /* cities with ≥ 20 % sales growth (no‑promo) from Q4‑2019 to Q4‑2020 */
    SELECT  cust_city
    FROM    us_q4_nopromo
    GROUP BY cust_city
    HAVING  SUM(CASE WHEN calendar_year = 2020 THEN amount_sold END) >=
            1.2 * SUM(CASE WHEN calendar_year = 2019 THEN amount_sold END)
),
filtered_sales AS (
    /* restrict to transactions in growth cities */
    SELECT u.*
    FROM   us_q4_nopromo u
    JOIN   growth_cities g USING (cust_city)
),
product_totals AS (
    /* total sales per product (both quarters) */
    SELECT  prod_id,
            SUM(amount_sold) AS tot_sales
    FROM    filtered_sales
    GROUP BY prod_id
),
ranked AS (
    /* rank products by value and keep top 20 % */
    SELECT  pt.*,
            RANK()       OVER (ORDER BY tot_sales DESC) AS rk,
            COUNT(*)     OVER ()                        AS cnt
    FROM    product_totals pt
),
top_products AS (
    SELECT prod_id
    FROM   ranked
    WHERE  rk <= 0.20 * cnt
),
prod_year_sales AS (
    /* annual sales of top products */
    SELECT  f.prod_id,
            f.calendar_year,
            SUM(f.amount_sold) AS sales_amt
    FROM    filtered_sales f
    JOIN    top_products  tp USING (prod_id)
    GROUP BY f.prod_id, f.calendar_year
),
year_totals AS (
    /* total sales (all products) per year in growth cities */
    SELECT  calendar_year,
            SUM(amount_sold) AS yr_total
    FROM    filtered_sales
    GROUP BY calendar_year
)
SELECT  pys.prod_id AS product,
        ROUND(
              (COALESCE(SUM(CASE WHEN pys.calendar_year = 2020 THEN pys.sales_amt END),0) * 1.0 /
               (SELECT yr_total FROM year_totals WHERE calendar_year = 2020))
            - (COALESCE(SUM(CASE WHEN pys.calendar_year = 2019 THEN pys.sales_amt END),0) * 1.0 /
               (SELECT yr_total FROM year_totals WHERE calendar_year = 2019))
        ,4) AS share_change,
        ROUND(
              COALESCE(SUM(CASE WHEN pys.calendar_year = 2019 THEN pys.sales_amt END),0) * 1.0 /
              (SELECT yr_total FROM year_totals WHERE calendar_year = 2019)
        ,4) AS share_q4_2019,
        ROUND(
              COALESCE(SUM(CASE WHEN pys.calendar_year = 2020 THEN pys.sales_amt END),0) * 1.0 /
              (SELECT yr_total FROM year_totals WHERE calendar_year = 2020)
        ,4) AS share_q4_2020
FROM    prod_year_sales pys
GROUP BY pys.prod_id
ORDER BY share_change DESC, product;