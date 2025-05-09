SELECT
  "Month",
  "Product_ID",
  ROUND("Total_Cost", 4) AS "Total_Cost",
  ROUND("Total_Profit", 4) AS "Total_Profit"
FROM
(
  SELECT
    TO_VARCHAR(TO_TIMESTAMP("oi"."created_at" / 1e6), 'YYYY-MM') AS "Month",
    "oi"."product_id" AS "Product_ID",
    SUM("inv"."cost") AS "Total_Cost",
    SUM("oi"."sale_price" - "inv"."cost") AS "Total_Profit",
    ROW_NUMBER() OVER (
      PARTITION BY TO_VARCHAR(TO_TIMESTAMP("oi"."created_at" / 1e6), 'YYYY-MM')
      ORDER BY SUM("oi"."sale_price" - "inv"."cost") DESC NULLS LAST
    ) AS "Rank"
  FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS AS "oi"
  INNER JOIN
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS AS "inv"
    ON "oi"."inventory_item_id" = "inv"."id"
  WHERE
    TO_TIMESTAMP("oi"."created_at" / 1e6) < DATE '2024-01-01'
    AND "oi"."status" = 'Complete'
  GROUP BY
    "Month",
    "Product_ID"
)
WHERE
  "Rank" = 1
ORDER BY
  "Month" ASC;