WITH us_sales AS (               -- USA sales in Q4‑2019 & Q4‑2020 that used promo 999
    SELECT  s.prod_id,
            cu.cust_city,
            t.calendar_year  AS yr,          -- 2019 or 2020
            s.amount_sold
    FROM    sales      s
    JOIN    customers  cu ON cu.cust_id   = s.cust_id
    JOIN    countries  co ON co.country_id = cu.country_id
    JOIN    times      t  ON t.time_id    = s.time_id
    WHERE   s.promo_id              = 999
      AND   co.country_iso_code     = 'US'          -- United States
      AND   t.calendar_quarter_number = 4           -- Q4 only
      AND   t.calendar_year IN (2019, 2020)
),--------------------------------------------------
city_year_sales AS (             -- total Q4 sales per city & year
    SELECT  cust_city AS city,
            yr,
            SUM(amount_sold) AS sales
    FROM    us_sales
    GROUP BY cust_city, yr
),--------------------------------------------------
city_growth AS (                 -- cities whose Q4‑2020 sales ≥ 120 % of Q4‑2019
    SELECT  c19.city
    FROM    city_year_sales c19
    JOIN    city_year_sales c20
           ON c19.city = c20.city
    WHERE   c19.yr = 2019
      AND   c20.yr = 2020
      AND   c19.sales > 0
      AND   c20.sales >= 1.2 * c19.sales
),--------------------------------------------------
filtered_sales AS (              -- keep only sales that happened in the “growing” cities
    SELECT  us.prod_id,
            us.yr,
            SUM(us.amount_sold) AS sales
    FROM    us_sales us
    WHERE   us.cust_city IN (SELECT city FROM city_growth)
    GROUP BY us.prod_id, us.yr
),--------------------------------------------------
product_total_sales AS (         -- combined 2019+2020 sales per product
    SELECT  prod_id,
            SUM(sales) AS total_sales
    FROM    filtered_sales
    GROUP BY prod_id
),--------------------------------------------------
ranked_products AS (             -- rank products by total sales
    SELECT  prod_id,
            total_sales,
            ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
            COUNT(*)    OVER ()                           AS cnt
    FROM    product_total_sales
),--------------------------------------------------
top_products AS (                -- top 20 % (ceiling) of products
    SELECT  prod_id
    FROM    ranked_products
    WHERE   rn <= (cnt + 4) / 5
),--------------------------------------------------
year_total_sales AS (            -- overall total per year (all products)
    SELECT  yr,
            SUM(sales) AS total_sales
    FROM    filtered_sales
    GROUP BY yr
),--------------------------------------------------
product_share AS (               -- each product’s share of that year’s total
    SELECT  fs.prod_id,
            fs.yr,
            fs.sales * 1.0 / yts.total_sales AS share
    FROM    filtered_sales fs
    JOIN    year_total_sales yts ON yts.yr = fs.yr
),--------------------------------------------------
product_change AS (              -- absolute change in share from 2019→2020
    SELECT  p19.prod_id,
            p19.share AS share_2019,
            p20.share AS share_2020,
            ABS(p20.share - p19.share) AS change
    FROM    product_share p19
    JOIN    product_share p20
           ON p19.prod_id = p20.prod_id
    WHERE   p19.yr = 2019
      AND   p20.yr = 2020
)--------------------------------------------------
SELECT  pc.prod_id
FROM    product_change pc
JOIN    top_products  tp ON tp.prod_id = pc.prod_id
ORDER BY pc.change ASC, pc.prod_id
LIMIT 1;