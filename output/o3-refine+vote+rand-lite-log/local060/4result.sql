WITH filtered_sales AS (          -- 1.  USA ‑ Q4 2019 / Q4 2020  &  NO‑PROMOTION (promo_id = 999)
    SELECT  s.prod_id,
            s.cust_id,
            s.time_id,
            s.amount_sold,
            c.cust_city,
            t.calendar_year,
            t.calendar_quarter_number
    FROM    sales      AS s
    JOIN    times      AS t   ON t.time_id = s.time_id
    JOIN    customers  AS c   ON c.cust_id = s.cust_id
    JOIN    countries  AS co  ON co.country_id = c.country_id
    WHERE   s.promo_id = 999                       -- “no promotion”
      AND   t.calendar_year IN (2019, 2020)
      AND   t.calendar_quarter_number = 4          -- Q4 only
      AND   co.country_name LIKE 'United States%'  -- U.S. cities
),
city_year_sales AS (             -- 2. sales per city & year
    SELECT  cust_city       AS city,
            calendar_year   AS year,
            SUM(amount_sold) AS total_sales
    FROM    filtered_sales
    GROUP BY cust_city, calendar_year
),
city_growth AS (                 -- 3. growth 2020 vs 2019
    SELECT  city,
            SUM(CASE WHEN year = 2019 THEN total_sales END) AS sales_2019,
            SUM(CASE WHEN year = 2020 THEN total_sales END) AS sales_2020
    FROM    city_year_sales
    GROUP BY city
),
selected_cities AS (             -- 4. cities with ≥ 20 % increase
    SELECT city
    FROM   city_growth
    WHERE  sales_2019 > 0
       AND sales_2020 >= 1.2 * sales_2019
),
selected_sales AS (              -- 5. keep sales from those cities
    SELECT  fs.*
    FROM    filtered_sales AS fs
    WHERE   fs.cust_city IN (SELECT city FROM selected_cities)
),
ranked_products AS (             -- 6. overall product sales, rank for top 20 %
    SELECT  prod_id,
            SUM(amount_sold) AS total_sales,
            NTILE(5) OVER (ORDER BY SUM(amount_sold) DESC) AS nt    -- 5 tiles ⇒ top 20 % = nt = 1
    FROM    selected_sales
    GROUP BY prod_id
),
top_products AS (                -- 7. keep only the top 20 %
    SELECT  prod_id
    FROM    ranked_products
    WHERE   nt = 1
),
product_year_sales AS (          -- 8. sales by product & year (top products)
    SELECT  ss.prod_id,
            ss.calendar_year AS year,
            SUM(ss.amount_sold) AS prod_sales
    FROM    selected_sales AS ss
    WHERE   ss.prod_id IN (SELECT prod_id FROM top_products)
    GROUP BY ss.prod_id, ss.calendar_year
),
total_year_sales AS (            -- 9. total sales each year (all products)
    SELECT  calendar_year AS year,
            SUM(amount_sold) AS total_sales
    FROM    selected_sales
    GROUP BY calendar_year
),
product_shares AS (              -- 10. share per product & year
    SELECT  pys.prod_id,
            pys.year,
            pys.prod_sales * 1.0 / tys.total_sales  AS share
    FROM    product_year_sales AS pys
    JOIN    total_year_sales  AS tys USING (year)
),
share_change AS (                -- 11. pivot & compute change
    SELECT  prod_id,
            COALESCE(MAX(CASE WHEN year = 2019 THEN share END),0) AS share_2019,
            COALESCE(MAX(CASE WHEN year = 2020 THEN share END),0) AS share_2020
    FROM    product_shares
    GROUP BY prod_id
)
-- 12. final result
SELECT  sc.prod_id,
        p.prod_name,
        ROUND(sc.share_2019,4) AS share_2019,
        ROUND(sc.share_2020,4) AS share_2020,
        ROUND(sc.share_2020 - sc.share_2019,4) AS share_change
FROM    share_change AS sc
JOIN    products     AS p  ON p.prod_id = sc.prod_id
ORDER BY share_change DESC, sc.prod_id;