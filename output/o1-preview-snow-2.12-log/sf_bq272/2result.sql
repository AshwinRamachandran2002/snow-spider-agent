WITH Profit_CTE AS (
  SELECT 
    DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6)) AS "MonthDate",
    p."name" AS "Product_Name",
    SUM(oi."sale_price") AS "Total_Sales",
    SUM(ii."cost") AS "Total_Cost",
    SUM(oi."sale_price" - ii."cost") AS "Profit"
  FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS oi
  JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" AS ii
    ON oi."inventory_item_id" = ii."id"
  JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS p
    ON oi."product_id" = p."id"
  WHERE oi."status" NOT IN ('Cancelled', 'Returned')
    AND TO_TIMESTAMP(oi."created_at" / 1e6) >= TO_TIMESTAMP('2019-01-01', 'YYYY-MM-DD')
    AND TO_TIMESTAMP(oi."created_at" / 1e6) <= TO_TIMESTAMP('2022-08-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
  GROUP BY "MonthDate", p."name"
),
Ranked_CTE AS (
  SELECT
    "MonthDate",
    TO_CHAR("MonthDate", 'Mon-YYYY') AS "Month",
    "Product_Name",
    ROUND("Profit", 4) AS "Profit",
    ROW_NUMBER() OVER (PARTITION BY "MonthDate" ORDER BY "Profit" DESC NULLS LAST) AS "Rank"
  FROM Profit_CTE
)
SELECT "Month", "Product_Name", "Profit"
FROM Ranked_CTE
WHERE "Rank" <= 3
ORDER BY
  "MonthDate",
  "Rank";