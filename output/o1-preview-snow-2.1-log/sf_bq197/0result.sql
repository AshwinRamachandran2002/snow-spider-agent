WITH MonthlyProductSales AS (
  SELECT
    TO_CHAR(TO_TIMESTAMP_LTZ(o."created_at" / 1e6), 'Mon-YYYY') AS "Month",
    o."product_id",
    p."name" AS "Product_Name",
    COUNT(*) AS "Sales_Volume",
    ROUND(SUM(o."sale_price"), 4) AS "Revenue"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS o
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
    ON o."product_id" = p."id"
  WHERE o."status" = 'Complete'
    AND TO_TIMESTAMP_LTZ(o."created_at" / 1e6) <= TIMESTAMP '2024-06-30 23:59:59'
  GROUP BY "Month", o."product_id", p."name"
)
SELECT
  MonthData."Month",
  MonthData."Product_Name",
  MonthData."Sales_Volume",
  MonthData."Revenue"
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY "Month"
      ORDER BY "Sales_Volume" DESC NULLS LAST, "Revenue" DESC NULLS LAST
    ) AS "Rank"
  FROM MonthlyProductSales
) MonthData
WHERE MonthData."Rank" = 1
ORDER BY TO_DATE(MonthData."Month", 'Mon-YYYY') ASC;