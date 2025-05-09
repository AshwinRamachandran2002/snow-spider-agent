WITH
/* 1. U.S. customers (assume country name starts with 'United States') */
us_customers AS (
    SELECT c.cust_id,
           c.cust_city
    FROM   customers  c
    JOIN   countries  co
           ON co.country_id = c.country_id
    WHERE  co.country_name LIKE 'United States%'
),

/* 2. Base sales in Q4‑2019 & Q4‑2020, no‑promotion rows (promo_id = 999)   */
base_sales AS (
    SELECT s.prod_id,
           uc.cust_city,
           t.calendar_year  AS yr,
           s.amount_sold
    FROM   sales  s
    JOIN   us_customers uc    ON uc.cust_id = s.cust_id
    JOIN   times       t      ON t.time_id  = s.time_id
    WHERE  s.promo_id               = 999
      AND  t.calendar_quarter_number = 4
      AND  t.calendar_year          IN (2019, 2020)
),

/* 3. Cities whose total sales rose ≥20 % from Q4‑2019 to Q4‑2020          */
city_year_sales AS (
    SELECT cust_city,
           SUM(CASE WHEN yr = 2019 THEN amount_sold END) AS sales_2019,
           SUM(CASE WHEN yr = 2020 THEN amount_sold END) AS sales_2020
    FROM   base_sales
    GROUP  BY cust_city
),
selected_cities AS (
    SELECT cust_city
    FROM   city_year_sales
    WHERE  sales_2019 IS NOT NULL
      AND  sales_2020 IS NOT NULL
      AND  sales_2019 > 0
      AND  sales_2020 >= 1.2 * sales_2019
),

/* 4. Sales restricted to those fast‑growing cities                       */
filtered_sales AS (
    SELECT bs.*
    FROM   base_sales bs
    JOIN   selected_cities sc ON sc.cust_city = bs.cust_city
),

/* 5. Total sales per product (both quarters together)                     */
prod_total_sales AS (
    SELECT prod_id,
           SUM(amount_sold) AS total_sales
    FROM   filtered_sales
    GROUP  BY prod_id
),
prod_count AS (SELECT COUNT(*) AS cnt FROM prod_total_sales),

/* 6. Rank products and keep the top 20 %                                  */
ranked_products AS (
    SELECT p.*,
           ROW_NUMBER() OVER (ORDER BY total_sales DESC)               AS rn,
           (SELECT cnt FROM prod_count)                                AS total_cnt
    FROM   prod_total_sales p
),
top_products AS (
    SELECT prod_id
    FROM   ranked_products
    WHERE  rn <= CAST(total_cnt*0.2 + 0.999999 AS INTEGER)   -- ceiling
),

/* 7. Sales of top products per quarter                                    */
product_quarter_sales AS (
    SELECT fs.prod_id,
           fs.yr,
           SUM(fs.amount_sold) AS prod_sales
    FROM   filtered_sales fs
    JOIN   top_products tp ON tp.prod_id = fs.prod_id
    GROUP  BY fs.prod_id, fs.yr
),

/* 8. Total sales (all products) per quarter in the same cities            */
total_quarter_sales AS (
    SELECT yr,
           SUM(amount_sold) AS total_sales
    FROM   filtered_sales
    GROUP  BY yr
),

/* 9. Shares of each top product in each quarter                           */
shares AS (
    SELECT p.prod_id,
           p.yr,
           p.prod_sales,
           t.total_sales,
           CAST(p.prod_sales AS REAL) / t.total_sales AS share
    FROM   product_quarter_sales p
    JOIN   total_quarter_sales t ON t.yr = p.yr
),

/* 10. Put the two years side‑by‑side                                      */
pivot AS (
    SELECT prod_id,
           MAX(CASE WHEN yr = 2019 THEN share END) AS share_2019,
           MAX(CASE WHEN yr = 2020 THEN share END) AS share_2020
    FROM   shares
    GROUP  BY prod_id
),

/* 11. Final computations                                                  */
final AS (
    SELECT prod_id,
           COALESCE(share_2019,0)                         AS share_2019,
           COALESCE(share_2020,0)                         AS share_2020,
           COALESCE(share_2020,0) - COALESCE(share_2019,0) AS share_change
    FROM   pivot
)

SELECT f.prod_id,
       pr.prod_name,
       ROUND(f.share_2019,4)  AS share_2019,
       ROUND(f.share_2020,4)  AS share_2020,
       ROUND(f.share_change,4) AS share_change
FROM   final      f
LEFT  JOIN products pr ON pr.prod_id = f.prod_id
ORDER BY share_change DESC,
         f.prod_id;