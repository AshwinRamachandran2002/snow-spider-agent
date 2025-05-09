WITH ProjectedSales AS (
  SELECT P."calendar_month_number", (P."projected_sales" * C."to_us") AS "projected_sales_usd"
  FROM
  (
      SELECT "calendar_month_number", AVG("total_sales") AS "projected_sales"
      FROM (
          SELECT T."calendar_year", T."calendar_month_number", SUM(S."amount_sold") AS "total_sales"
          FROM "sales" S
          JOIN "times" T ON S."time_id" = T."time_id"
          WHERE S."cust_id" IN (
              SELECT "cust_id" FROM "customers" WHERE "country_id" = (
                  SELECT "country_id" FROM "countries" WHERE "country_name" = 'France'
              )
          ) AND T."calendar_year" IN (2019, 2020)
          GROUP BY T."calendar_year", T."calendar_month_number"
      ) AS MonthlySales
      GROUP BY "calendar_month_number"
  ) P
  JOIN "currency" C
  ON C."country" = 'France' AND C."year" = 2021 AND C."month" = P."calendar_month_number"
)
SELECT AVG("projected_sales_usd") AS "Median_average_monthly_projected_sales_USD"
FROM (
  SELECT "projected_sales_usd"
  FROM ProjectedSales
  ORDER BY "projected_sales_usd"
  LIMIT 2 OFFSET 5
);