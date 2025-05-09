WITH
TotalProducts AS (
  SELECT COUNT(DISTINCT "prod_id") AS "product_count" FROM "sales"
),
TotalSalesPerProduct AS (
  SELECT "prod_id", SUM("amount_sold") AS "total_amount_sold"
  FROM "sales"
  GROUP BY "prod_id"
),
TopProducts AS (
  SELECT "prod_id"
  FROM TotalSalesPerProduct
  ORDER BY "total_amount_sold" DESC
  LIMIT CAST((SELECT "product_count" FROM TotalProducts) * 0.2 AS INTEGER)
),
TotalPeriodSales AS (
  SELECT t."calendar_year" AS "year", SUM(s."amount_sold") AS "total_amount"
  FROM "sales" s
  JOIN "times" t ON s."time_id" = t."time_id"
  JOIN "customers" c ON s."cust_id" = c."cust_id"
  JOIN "countries" co ON c."country_id" = co."country_id"
  LEFT JOIN "promotions" p ON s."promo_id" = p."promo_id"
  WHERE t."calendar_quarter_number" = 4
    AND co."country_iso_code" = 'US'
    AND (
      p."promo_name" LIKE 'No Promotion%' OR
      p."promo_cost" = 0 OR
      s."promo_id" NOT IN (SELECT "promo_id" FROM "promotions")
    )
    AND t."calendar_year" IN (2019, 2020)
  GROUP BY t."calendar_year"
),
SalesData AS (
  SELECT
    s."prod_id",
    t."calendar_year" AS "year",
    SUM(s."amount_sold") AS "product_amount"
  FROM "sales" s
  JOIN "times" t ON s."time_id" = t."time_id"
  JOIN "customers" c ON s."cust_id" = c."cust_id"
  JOIN "countries" co ON c."country_id" = co."country_id"
  LEFT JOIN "promotions" p ON s."promo_id" = p."promo_id"
  WHERE t."calendar_quarter_number" = 4
    AND t."calendar_year" IN (2019, 2020)
    AND co."country_iso_code" = 'US'
    AND (
      p."promo_name" LIKE 'No Promotion%' OR
      p."promo_cost" = 0 OR
      s."promo_id" NOT IN (SELECT "promo_id" FROM "promotions")
    )
    AND s."prod_id" IN (SELECT "prod_id" FROM TopProducts)
  GROUP BY s."prod_id", t."calendar_year"
),
SalesShare AS (
  SELECT
    s."prod_id",
    s."year",
    s."product_amount" / tp."total_amount" AS "sales_share"
  FROM SalesData s
  JOIN TotalPeriodSales tp ON s."year" = tp."year"
),
SalesSharePivot AS (
  SELECT
    "prod_id",
    COALESCE(MAX(CASE WHEN "year" = 2019 THEN "sales_share" END), 0) AS "sales_share_2019",
    COALESCE(MAX(CASE WHEN "year" = 2020 THEN "sales_share" END), 0) AS "sales_share_2020"
  FROM SalesShare
  GROUP BY "prod_id"
),
SalesShareChange AS (
  SELECT
    "prod_id",
    ABS("sales_share_2020" - "sales_share_2019") AS "change_in_share"
  FROM SalesSharePivot
)
SELECT
  p."prod_name" AS "Product_Name"
FROM SalesShareChange ssc
JOIN "products" p ON ssc."prod_id" = p."prod_id"
ORDER BY ssc."change_in_share" ASC
LIMIT 1;