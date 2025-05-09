WITH
-- 1.  United‑States sales in Q4‑2019 and Q4‑2020 that had NO promotion (promo_id = 999)
us_sales AS (
    SELECT  s.prod_id ,
            s.cust_id ,
            s.amount_sold ,
            t.calendar_year ,
            t.calendar_quarter_number ,
            cu.cust_city
    FROM    sales      AS s
    JOIN    times      AS t  ON t.time_id  = s.time_id
    JOIN    customers  AS cu ON cu.cust_id = s.cust_id
    JOIN    countries  AS co ON co.country_id = cu.country_id
    WHERE   co.country_iso_code = 'US'          -- United States
      AND   s.promo_id           = 999          -- “no promotion”
      AND   t.calendar_quarter_number = 4
      AND   t.calendar_year IN (2019,2020)
),

-- 2.  City totals for each quarter
city_qtr_totals AS (
    SELECT  cust_city,
            calendar_year,
            SUM(amount_sold) AS city_sales
    FROM    us_sales
    GROUP BY cust_city , calendar_year
),

-- 3.  Cities whose Q4‑2020 sales ≥ 120 % of their Q4‑2019 sales
rising_cities AS (
    SELECT  c19.cust_city
    FROM    city_qtr_totals  AS c19
    JOIN    city_qtr_totals  AS c20
           ON c20.cust_city = c19.cust_city
          AND c19.calendar_year = 2019
          AND c20.calendar_year = 2020
    WHERE   c20.city_sales >= 1.20 * c19.city_sales
),

-- 4.  All sales (still “no promotion”) that took place in those rising cities
eligible_sales AS (
    SELECT  s.*
    FROM    us_sales AS s
    JOIN    rising_cities AS rc ON rc.cust_city = s.cust_city
),

-- 5.  Product totals across BOTH quarters, used for ranking
product_totals AS (
    SELECT  prod_id,
            SUM(amount_sold) AS total_amt
    FROM    eligible_sales
    GROUP BY prod_id
),

-- 6.  Rank products and keep the top 20 %
ranked_products AS (
    SELECT  prod_id,
            total_amt,
            ROW_NUMBER() OVER (ORDER BY total_amt DESC) AS rn,
            COUNT(*)    OVER ()                            AS cnt
    FROM    product_totals
),
top_products AS (                      -- ceiling(cnt*0.20)  →  (cnt+4)/5
    SELECT  prod_id
    FROM    ranked_products
    WHERE   rn <= (cnt + 4) / 5
),

-- 7.  Product‑quarter sales for the selected cities
prod_qtr_sales AS (
    SELECT  es.prod_id,
            es.calendar_year,
            SUM(es.amount_sold) AS prod_qtr_amt
    FROM    eligible_sales AS es
    GROUP BY es.prod_id , es.calendar_year
),

-- 8.  Quarter totals for ALL products (selected cities)
qtr_totals AS (
    SELECT  calendar_year,
            SUM(amount_sold) AS qtr_amt
    FROM    eligible_sales
    GROUP BY calendar_year
)

-- 9.  Final report
SELECT  tp.prod_id,
        pr.prod_name,
        ROUND(COALESCE(p19.prod_qtr_amt,0) * 1.0 / qt19.qtr_amt , 4) AS share_2019 ,
        ROUND(COALESCE(p20.prod_qtr_amt,0) * 1.0 / qt20.qtr_amt , 4) AS share_2020 ,
        ROUND( (COALESCE(p20.prod_qtr_amt,0) * 1.0 / qt20.qtr_amt) 
             - (COALESCE(p19.prod_qtr_amt,0) * 1.0 / qt19.qtr_amt) , 4) AS share_change
FROM        top_products      AS tp
LEFT  JOIN  prod_qtr_sales    AS p19 ON p19.prod_id = tp.prod_id AND p19.calendar_year = 2019
LEFT  JOIN  prod_qtr_sales    AS p20 ON p20.prod_id = tp.prod_id AND p20.calendar_year = 2020
JOIN        qtr_totals        AS qt19 ON qt19.calendar_year = 2019
JOIN        qtr_totals        AS qt20 ON qt20.calendar_year = 2020
LEFT  JOIN  products          AS pr   ON pr.prod_id = tp.prod_id
ORDER BY    share_change DESC ,
            tp.prod_id;