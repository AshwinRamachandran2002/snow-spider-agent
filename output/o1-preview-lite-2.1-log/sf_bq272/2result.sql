SELECT "Month", "Product_Name", "Total_Profit"
FROM (
  SELECT
    TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'Mon-YYYY') AS "Month",
    p."name" AS "Product_Name",
    ROUND(SUM(oi."sale_price" - p."cost"), 4) AS "Total_Profit",
    ROW_NUMBER() OVER (
      PARTITION BY TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'Mon-YYYY')
      ORDER BY SUM(oi."sale_price" - p."cost") DESC NULLS LAST
    ) AS "Rank"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    ON oi."product_id" = p."id"
  WHERE oi."status" NOT IN ('Cancelled', 'Returned')
    AND oi."created_at" >= 1546300800000000  -- Jan 1, 2019 in microseconds
    AND oi."created_at" < 1661990400000000   -- Sep 1, 2022 in microseconds
  GROUP BY
    TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'Mon-YYYY'),
    p."name"
) sub
WHERE "Rank" <= 3
ORDER BY
  TO_DATE("Month", 'Mon-YYYY') ASC,
  "Rank" ASC;