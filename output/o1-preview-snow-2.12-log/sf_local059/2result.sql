WITH TotalSales AS (
  SELECT
    p."division",
    s."product_code",
    SUM(s."sold_quantity") AS total_quantity_sold
  FROM
    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" s
  JOIN
    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_DIM_PRODUCT" p
      ON s."product_code" = p."product_code"
  WHERE
    s."date" LIKE '2021%'
  GROUP BY
    p."division",
    s."product_code"
),
RankedSales AS (
  SELECT
    "division",
    "product_code",
    total_quantity_sold,
    RANK() OVER (PARTITION BY "division" ORDER BY total_quantity_sold DESC NULLS LAST) AS product_rank
  FROM
    TotalSales
),
Top3Products AS (
  SELECT
    "division",
    "product_code"
  FROM
    RankedSales
  WHERE
    product_rank <= 3
),
Top3ProductTransactions AS (
  SELECT
    s."product_code",
    s."sold_quantity",
    tp."division"
  FROM
    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" s
  JOIN
    Top3Products tp
      ON s."product_code" = tp."product_code"
  WHERE
    s."date" LIKE '2021%'
)
SELECT
  "division" AS "Division",
  ROUND(AVG("sold_quantity"), 4) AS "Overall_Average_Quantity_Sold"
FROM
  Top3ProductTransactions
GROUP BY
  "division"