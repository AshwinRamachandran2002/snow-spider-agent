WITH q4_times AS (          /* Q4 of 2019 & 2020                                            */
    SELECT "time_id",
           "calendar_year"  AS "year"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"
    WHERE  "calendar_year" IN (2019, 2020)
      AND  "calendar_quarter_number" = 4
),
us_sales AS (               /* U.S. sales without promotions in those quarters            */
    SELECT  s."amount_sold",
            s."prod_id",
            cu."cust_city"        AS "city",
            t."year"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"      s
    JOIN   q4_times                                   t  ON s."time_id" = t."time_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  cu ON s."cust_id" = cu."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  co ON cu."country_id" = co."country_id"
    WHERE  co."country_iso_code" = 'US'
      AND  s."promo_id" = 999                         /* 999 = no promotion             */
),
city_q_sales AS (           /* City-level totals for each year                            */
    SELECT  "city",
            "year",
            SUM("amount_sold") AS "city_sales"
    FROM    us_sales
    GROUP BY "city","year"
),
growing_cities AS (         /* Cities whose Q4 2020 sales rose ≥ 20 % vs Q4 2019          */
    SELECT  a."city"
    FROM    city_q_sales a
    JOIN    city_q_sales b
           ON a."city" = b."city"
    WHERE   a."year" = 2019
      AND   b."year" = 2020
      AND   b."city_sales" >= a."city_sales" * 1.2
),
filtered_sales AS (         /* Sales restricted to those cities                           */
    SELECT  *
    FROM    us_sales
    WHERE   "city" IN (SELECT "city" FROM growing_cities)
),
prod_ranking AS (           /* Rank products by combined Q4-19 & Q4-20 sales              */
    SELECT  "prod_id",
            SUM("amount_sold")                               AS "total_prod_sales",
            PERCENT_RANK() OVER (ORDER BY SUM("amount_sold") DESC) AS "pct_rank"
    FROM    filtered_sales
    GROUP BY "prod_id"
),
top_products AS (           /* Keep top 20 %                                               */
    SELECT  "prod_id"
    FROM    prod_ranking
    WHERE   "pct_rank" <= 0.20
),
sales_final AS (            /* Top products – sales by year                               */
    SELECT  fs."prod_id",
            fs."year",
            SUM(fs."amount_sold") AS "prod_year_sales"
    FROM    filtered_sales fs
    JOIN    top_products   tp ON fs."prod_id" = tp."prod_id"
    GROUP BY fs."prod_id", fs."year"
),
total_year_sales AS (       /* Overall sales (all products) per year in the same cities   */
    SELECT  "year",
            SUM("amount_sold") AS "year_total_sales"
    FROM    filtered_sales
    GROUP BY "year"
),
shares AS (                 /* Build sales & shares table                                 */
    SELECT  sf."prod_id",
            COALESCE(SUM(CASE WHEN sf."year" = 2019 THEN sf."prod_year_sales" END),0) AS "sales_2019",
            COALESCE(SUM(CASE WHEN sf."year" = 2020 THEN sf."prod_year_sales" END),0) AS "sales_2020"
    FROM    sales_final sf
    GROUP BY sf."prod_id"
),
shares_with_ratio AS (      /* Calculate shares                                            */
    SELECT  sh."prod_id",
            sh."sales_2019" / ty19."year_total_sales" AS "share_2019",
            sh."sales_2020" / ty20."year_total_sales" AS "share_2020"
    FROM    shares sh
    LEFT JOIN total_year_sales ty19 ON ty19."year" = 2019
    LEFT JOIN total_year_sales ty20 ON ty20."year" = 2020
)
SELECT  swr."prod_id",
        pr."prod_name",
        ROUND(swr."share_2019",4)                  AS "share_2019",
        ROUND(swr."share_2020",4)                  AS "share_2020",
        ROUND(swr."share_2020" - swr."share_2019",4) AS "share_change"
FROM    shares_with_ratio swr
JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."PRODUCTS" pr
       ON swr."prod_id" = pr."prod_id"
ORDER BY "share_change" DESC NULLS LAST;