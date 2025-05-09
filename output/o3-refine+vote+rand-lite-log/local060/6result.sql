WITH
/* 1. United‑States Q4 sales that used NO promotion (promo_id = 999)               */
us_q4_sales AS (
    SELECT  s.prod_id ,
            s.amount_sold ,
            c.cust_city ,
            t.calendar_year
    FROM            sales      s
    JOIN            customers  c  ON c.cust_id   = s.cust_id
    JOIN            countries  co ON co.country_id = c.country_id
    JOIN            times      t  ON t.time_id   = s.time_id
    WHERE   co.country_iso_code = 'US'              -- United States
        AND t.calendar_quarter_number = 4           -- Q4
        AND t.calendar_year IN (2019,2020)
        AND s.promo_id = 999                        -- “no‑promotion” rows
),

/* 2.  Cities whose Q4 2020 sales are ≥ 120 % of their Q4 2019 sales               */
city_year_sales AS (
    SELECT  cust_city                               AS city,
            calendar_year                           AS yr,
            SUM(amount_sold)                        AS sales
    FROM    us_q4_sales
    GROUP BY cust_city , calendar_year
),
rising_cities AS (
    SELECT city
    FROM   city_year_sales
    GROUP  BY city
    HAVING SUM(CASE WHEN yr = 2019 THEN sales END) > 0
       AND SUM(CASE WHEN yr = 2020 THEN sales END) >=
           1.2 * SUM(CASE WHEN yr = 2019 THEN sales END)
),

/* 3.  Keep only sales that happened in those “rising” cities                      */
filtered_sales AS (
    SELECT *
    FROM   us_q4_sales
    WHERE  cust_city IN (SELECT city FROM rising_cities)
),

/* 4.  Rank products by combined Q4 2019+2020 sales and keep the top 20 %          */
product_totals AS (
    SELECT  prod_id,
            SUM(amount_sold)       AS tot_sales
    FROM    filtered_sales
    GROUP BY prod_id
),
ranked_products AS (
    SELECT  prod_id,
            tot_sales,
            PERCENT_RANK() OVER (ORDER BY tot_sales DESC) AS pr
    FROM    product_totals
),
top_products AS (
    SELECT prod_id
    FROM   ranked_products
    WHERE  pr <= 0.20                                   -- top 20 %
),

/* 5.  Year totals (for denominator) and product‑year totals (for numerator)       */
year_totals AS (
    SELECT  calendar_year AS yr,
            SUM(amount_sold) AS tot_sales
    FROM    filtered_sales
    GROUP BY calendar_year
),
product_year_sales AS (
    SELECT  fs.prod_id,
            fs.calendar_year      AS yr,
            SUM(fs.amount_sold)   AS sales
    FROM    filtered_sales fs
    WHERE   fs.prod_id IN (SELECT prod_id FROM top_products)
    GROUP BY fs.prod_id , fs.calendar_year
)

/* 6.  Produce required shares and share‑change                                    */
SELECT  p.prod_id,
        p.prod_name,
        /* share in Q4‑2019 */
        COALESCE( SUM(CASE WHEN pys.yr = 2019 THEN pys.sales END), 0) * 1.0 /
        (SELECT tot_sales FROM year_totals WHERE yr = 2019)           AS share_2019,

        /* share in Q4‑2020 */
        COALESCE( SUM(CASE WHEN pys.yr = 2020 THEN pys.sales END), 0) * 1.0 /
        (SELECT tot_sales FROM year_totals WHERE yr = 2020)           AS share_2020,

        /* change in share */
        ( COALESCE( SUM(CASE WHEN pys.yr = 2020 THEN pys.sales END), 0) * 1.0 /
          (SELECT tot_sales FROM year_totals WHERE yr = 2020) ) -
        ( COALESCE( SUM(CASE WHEN pys.yr = 2019 THEN pys.sales END), 0) * 1.0 /
          (SELECT tot_sales FROM year_totals WHERE yr = 2019) )       AS share_change
FROM    product_year_sales pys
JOIN    products p  ON p.prod_id = pys.prod_id
GROUP BY p.prod_id, p.prod_name
ORDER BY share_change DESC, p.prod_id;