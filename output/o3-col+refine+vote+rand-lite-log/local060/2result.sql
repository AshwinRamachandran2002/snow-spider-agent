WITH us_cities_sales AS (          -- Q4-2019 / Q4-2020 “no-promotion” sales per U.S. city
    SELECT  c.cust_city,
            SUM(CASE WHEN t.calendar_year = 2019 THEN s.amount_sold END) AS total_2019,
            SUM(CASE WHEN t.calendar_year = 2020 THEN s.amount_sold END) AS total_2020
    FROM    sales      AS s
    JOIN    times      AS t  ON t.time_id = s.time_id
    JOIN    customers  AS c  ON c.cust_id = s.cust_id
    JOIN    countries  AS co ON co.country_id = c.country_id
    WHERE   co.country_name LIKE 'United States%'      -- only U.S.A.
      AND   t.calendar_quarter_number = 4
      AND   t.calendar_year IN (2019,2020)
      AND   s.promo_id = 999                           -- “no promotion”
    GROUP BY c.cust_city
),                                                    -- cities whose sales rose ≥20 %
qual_cities AS (
    SELECT cust_city
    FROM   us_cities_sales
    WHERE  total_2019 > 0
      AND  total_2020 >= 1.20 * total_2019
),                                                    -- product sales (both Q4s) inside the qualifying cities
city_product_sales AS (
    SELECT  s.prod_id,
            SUM(s.amount_sold) AS total_both_qtrs
    FROM    sales      AS s
    JOIN    times      AS t  ON t.time_id = s.time_id
    JOIN    customers  AS c  ON c.cust_id = s.cust_id
    WHERE   c.cust_city IN (SELECT cust_city FROM qual_cities)
      AND   t.calendar_quarter_number = 4
      AND   t.calendar_year IN (2019,2020)
      AND   s.promo_id = 999
    GROUP BY s.prod_id
),                                                    -- rank products, keep top 20 %
ranked_products AS (
    SELECT  prod_id,
            total_both_qtrs,
            ROW_NUMBER() OVER (ORDER BY total_both_qtrs DESC)              AS rn,
            COUNT(*)    OVER ()                                            AS cnt
    FROM    city_product_sales
), top_products AS (
    SELECT prod_id
    FROM   ranked_products
    WHERE  rn <= cnt * 0.20                               -- top 20 %
),                                                    -- per-product, per-year sales in qualifying cities
product_year_sales AS (
    SELECT  s.prod_id,
            t.calendar_year,
            SUM(s.amount_sold) AS amt
    FROM    sales      AS s
    JOIN    times      AS t  ON t.time_id = s.time_id
    JOIN    customers  AS c  ON c.cust_id = s.cust_id
    WHERE   c.cust_city IN (SELECT cust_city FROM qual_cities)
      AND   t.calendar_quarter_number = 4
      AND   t.calendar_year IN (2019,2020)
      AND   s.promo_id = 999
      AND   s.prod_id IN (SELECT prod_id FROM top_products)
    GROUP BY s.prod_id, t.calendar_year
),                                                    -- total sales (denominator) for each year
totals AS (
    SELECT  t.calendar_year,
            SUM(s.amount_sold) AS tot_amt
    FROM    sales      AS s
    JOIN    times      AS t  ON t.time_id = s.time_id
    JOIN    customers  AS c  ON c.cust_id = s.cust_id
    WHERE   c.cust_city IN (SELECT cust_city FROM qual_cities)
      AND   t.calendar_quarter_number = 4
      AND   t.calendar_year IN (2019,2020)
      AND   s.promo_id = 999
    GROUP BY t.calendar_year
),                                                    -- assemble shares & deltas
shares AS (
    SELECT  p.prod_id,
            COALESCE(SUM(CASE WHEN p.calendar_year = 2019 THEN p.amt END),0) /
            (SELECT tot_amt FROM totals WHERE calendar_year = 2019)          AS share_2019,
            COALESCE(SUM(CASE WHEN p.calendar_year = 2020 THEN p.amt END),0) /
            (SELECT tot_amt FROM totals WHERE calendar_year = 2020)          AS share_2020
    FROM    product_year_sales  p
    GROUP BY p.prod_id
)
SELECT  prod_id,
        ROUND(share_2019,4)                  AS share_2019_q4,
        ROUND(share_2020,4)                  AS share_2020_q4,
        ROUND(share_2020 - share_2019,4)     AS share_change
FROM    shares
ORDER BY share_change DESC;