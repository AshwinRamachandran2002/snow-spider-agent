WITH product_totals AS (
  SELECT dp."division", sfm."product_code", SUM(sfm."sold_quantity") AS total_quantity_sold_2021
  FROM "hardware_fact_sales_monthly" AS sfm
  JOIN "hardware_dim_product" AS dp
    ON sfm."product_code" = dp."product_code"
  WHERE sfm."date" LIKE '2021-%'
  GROUP BY dp."division", sfm."product_code"
),
ranked_products AS (
  SELECT
    pt."division",
    pt."product_code",
    pt.total_quantity_sold_2021,
    ROW_NUMBER() OVER (PARTITION BY pt."division" ORDER BY pt.total_quantity_sold_2021 DESC) AS rn
  FROM product_totals AS pt
)
SELECT
  rp."division" AS Division,
  ROUND(AVG(rp.total_quantity_sold_2021), 4) AS Average_Quantity_Sold
FROM ranked_products AS rp
WHERE rp.rn <= 3
GROUP BY rp."division";