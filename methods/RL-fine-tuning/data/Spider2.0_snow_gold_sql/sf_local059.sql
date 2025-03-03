WITH product_totals AS (
  SELECT
    s."product_code",
    SUM(s."sold_quantity") AS total_quantity_sold
  FROM
    EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_FACT_SALES_MONTHLY" s
  WHERE
    s."date" >= '2021-01-01' AND s."date" <= '2021-12-31'
  GROUP BY
    s."product_code"
),
product_with_division AS (
  SELECT
    pt."product_code",
    pt.total_quantity_sold,
    p."division"
  FROM
    product_totals pt
  JOIN
    EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_DIM_PRODUCT" p
  ON
    pt."product_code" = p."product_code"
),
ranked_products AS (
  SELECT
    pwd.*,
    ROW_NUMBER() OVER (PARTITION BY pwd."division" ORDER BY pwd.total_quantity_sold DESC NULLS LAST) AS division_rank
  FROM
    product_with_division pwd
),
top_products AS (
  SELECT
    "product_code",
    "division"
  FROM
    ranked_products
  WHERE
    division_rank <= 3
)
SELECT
  tp."division" AS "Division",
  ROUND(SUM(s."sold_quantity")::FLOAT / COUNT(*), 4) AS "Overall_Average_Quantity_Sold"
FROM
  EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_FACT_SALES_MONTHLY" s
JOIN
  top_products tp
ON
  s."product_code" = tp."product_code"
WHERE
  s."date" >= '2021-01-01' AND s."date" <= '2021-12-31'
GROUP BY
  tp."division"
ORDER BY
  tp."division";