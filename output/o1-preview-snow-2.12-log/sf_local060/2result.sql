WITH
Sales2019 AS (
  SELECT C."cust_city", SUM(S."amount_sold") AS "total_sales_2019"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" S
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" C ON S."cust_id" = C."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" CT ON C."country_id" = CT."country_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" T ON S."time_id" = T."time_id"
  WHERE CT."country_name" = 'United States of America'
    AND T."calendar_year" = 2019
    AND T."calendar_quarter_number" = 4
  GROUP BY C."cust_city"
),
Sales2020 AS (
  SELECT C."cust_city", SUM(S."amount_sold") AS "total_sales_2020"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" S
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" C ON S."cust_id" = C."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" CT ON C."country_id" = CT."country_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" T ON S."time_id" = T."time_id"
  WHERE CT."country_name" = 'United States of America'
    AND T."calendar_year" = 2020
    AND T."calendar_quarter_number" = 4
  GROUP BY C."cust_city"
),
CitiesWithGrowth AS (
  SELECT S2019."cust_city",
         S2019."total_sales_2019",
         S2020."total_sales_2020",
         ((S2020."total_sales_2020" - S2019."total_sales_2019") / NULLIF(S2019."total_sales_2019", 0)) * 100 AS "percentage_growth"
  FROM Sales2019 S2019
  JOIN Sales2020 S2020 ON S2019."cust_city" = S2020."cust_city"
  WHERE ((S2020."total_sales_2020" - S2019."total_sales_2019") / NULLIF(S2019."total_sales_2019", 0)) * 100 >= 20
),
TotalSalesInCitiesByProduct AS (
  SELECT S."prod_id",
         SUM(S."amount_sold") AS "total_sales"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" S
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" C ON S."cust_id" = C."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" T ON S."time_id" = T."time_id"
  WHERE T."calendar_year" IN (2019, 2020)
    AND T."calendar_quarter_number" = 4
    AND C."cust_city" IN (SELECT "cust_city" FROM CitiesWithGrowth)
  GROUP BY S."prod_id"
),
RankedProducts AS (
  SELECT TSP."prod_id",
         TSP."total_sales",
         NTILE(5) OVER (ORDER BY TSP."total_sales" DESC) AS "tile"
  FROM TotalSalesInCitiesByProduct TSP
),
TopProducts AS (
  SELECT "prod_id"
  FROM RankedProducts
  WHERE "tile" = 1
),
ProductSales AS (
  SELECT S."prod_id",
         SUM(CASE WHEN T."calendar_year" = 2019 THEN S."amount_sold" ELSE 0 END) AS "sales_2019",
         SUM(CASE WHEN T."calendar_year" = 2020 THEN S."amount_sold" ELSE 0 END) AS "sales_2020"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" S
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" C ON S."cust_id" = C."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" T ON S."time_id" = T."time_id"
  WHERE T."calendar_year" IN (2019, 2020)
    AND T."calendar_quarter_number" = 4
    AND C."cust_city" IN (SELECT "cust_city" FROM CitiesWithGrowth)
    AND S."prod_id" IN (SELECT "prod_id" FROM TopProducts)
  GROUP BY S."prod_id"
),
TotalSales AS (
  SELECT
    SUM(CASE WHEN T."calendar_year" = 2019 THEN S."amount_sold" ELSE 0 END) AS "total_sales_2019",
    SUM(CASE WHEN T."calendar_year" = 2020 THEN S."amount_sold" ELSE 0 END) AS "total_sales_2020"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" S
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" C ON S."cust_id" = C."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" T ON S."time_id" = T."time_id"
  WHERE T."calendar_year" IN (2019, 2020)
    AND T."calendar_quarter_number" = 4
    AND C."cust_city" IN (SELECT "cust_city" FROM CitiesWithGrowth)
)
SELECT
  P."prod_id" AS "Product_ID",
  P."prod_name" AS "Product_Name",
  ROUND(PS."sales_2019" / NULLIF(TS."total_sales_2019", 0), 4) AS "Share_Q4_2019",
  ROUND(PS."sales_2020" / NULLIF(TS."total_sales_2020", 0), 4) AS "Share_Q4_2020",
  ROUND((PS."sales_2020" / NULLIF(TS."total_sales_2020", 0)) - (PS."sales_2019" / NULLIF(TS."total_sales_2019", 0)), 4) AS "Share_Change"
FROM ProductSales PS
CROSS JOIN TotalSales TS
JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PRODUCTS" P ON P."prod_id" = PS."prod_id"
ORDER BY "Share_Change" DESC NULLS LAST
;