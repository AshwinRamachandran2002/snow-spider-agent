/*--------------------------------------------------------------------
  Smallest share-change product (top-20 % sales) among U.S. promo-999
  cities whose Q4-2020 sales grew ≥20 % vs Q4-2019
--------------------------------------------------------------------*/
WITH us_customers AS (                -- all U.S. customers
    SELECT cu."cust_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  cu
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES  co
           ON cu."country_id" = co."country_id"
    WHERE  co."country_name" ILIKE 'United States%'      -- U.S. only
),

sales_us AS (                         -- promo-999 sales by those customers
    SELECT  s."prod_id",
            s."cust_id",
            s."time_id",
            s."amount_sold"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE.SALES  s
    WHERE   s."promo_id" = 999
      AND   s."cust_id" IN (SELECT "cust_id" FROM us_customers)
),

sales_qtr_city AS (                   -- add quarter id & city, keep Q4-19/20
    SELECT  su.*,
            t."calendar_quarter_id",
            cu."cust_city"
    FROM    sales_us                       su
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t
           ON su."time_id" = t."time_id"
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  cu
           ON su."cust_id" = cu."cust_id"
    WHERE   t."calendar_quarter_id" IN (1772, 1776)      -- Q4-2019 / Q4-2020
),

city_growth_ok AS (                   -- cities with ≥20 % growth
    SELECT  "cust_city",
            SUM(CASE WHEN "calendar_quarter_id" = 1772 THEN "amount_sold" END) AS sales_2019,
            SUM(CASE WHEN "calendar_quarter_id" = 1776 THEN "amount_sold" END) AS sales_2020
    FROM    sales_qtr_city
    GROUP BY "cust_city"
    HAVING  sales_2020 >= 1.20 * sales_2019
),

filtered_sales AS (                   -- final fact set to analyse
    SELECT sqc.*
    FROM   sales_qtr_city sqc
    JOIN   city_growth_ok cg
           ON sqc."cust_city" = cg."cust_city"
),

prod_tot AS (                         -- total sales per product (filtered set)
    SELECT  "prod_id",
            SUM("amount_sold") AS tot_sales
    FROM    filtered_sales
    GROUP BY "prod_id"
),

ranked AS (                           -- percentile rank for top 20 %
    SELECT  "prod_id",
            tot_sales,
            PERCENT_RANK() OVER (ORDER BY tot_sales DESC) AS prank
    FROM    prod_tot
),

top20 AS (                            -- products in the top 20 % of sales
    SELECT "prod_id"
    FROM   ranked
    WHERE  prank <= 0.20
),

prod_qtr AS (                         -- product sales by quarter
    SELECT  "prod_id",
            "calendar_quarter_id",
            SUM("amount_sold") AS sales
    FROM    filtered_sales
    WHERE   "prod_id" IN (SELECT "prod_id" FROM top20)
    GROUP BY "prod_id", "calendar_quarter_id"
),

qtr_market AS (                       -- market total by quarter
    SELECT  "calendar_quarter_id",
            SUM("amount_sold") AS market_sales
    FROM    filtered_sales
    GROUP BY "calendar_quarter_id"
),

share AS (                            -- product share (%) by quarter
    SELECT  pq."prod_id",
            pq."calendar_quarter_id",
            100.0 * pq.sales / qm.market_sales AS pct_share
    FROM    prod_qtr  pq
    JOIN    qtr_market qm
           ON pq."calendar_quarter_id" = qm."calendar_quarter_id"
),

delta AS (                            -- percentage-point change in share
    SELECT  "prod_id",
            MAX(CASE WHEN "calendar_quarter_id" = 1776 THEN pct_share END) 
          - MAX(CASE WHEN "calendar_quarter_id" = 1772 THEN pct_share END) 
            AS pp_change
    FROM    share
    GROUP BY "prod_id"
),

rank_change AS (                      -- rank by absolute change
    SELECT  "prod_id",
            pp_change,
            ABS(pp_change) AS abs_change,
            ROW_NUMBER() OVER (ORDER BY ABS(pp_change) ASC) AS rn
    FROM    delta
)

SELECT  "prod_id",
        pp_change
FROM    rank_change
WHERE   rn = 1;                       -- product with the smallest share change