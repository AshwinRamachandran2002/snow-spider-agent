WITH monthly_data AS (
  SELECT
    TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1e6), 'YYYY-MM') AS "Month",
    p."category" AS "Product_Category",
    COUNT(DISTINCT oi."order_id") AS "Total_Orders",
    ROUND(SUM(oi."sale_price"), 4) AS "Total_Revenue",
    ROUND(SUM(oi."sale_price" - p."cost"), 4) AS "Total_Profit"
  FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
  JOIN
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    ON oi."product_id" = p."id"
  WHERE
    TO_TIMESTAMP_NTZ(oi."created_at" / 1e6) BETWEEN '2019-06-01' AND '2019-12-31'
  GROUP BY
    "Month",
    p."category"
),
june_data AS (
  SELECT
    p."category" AS "Product_Category",
    COUNT(DISTINCT oi."order_id") AS "Total_Orders_June",
    SUM(oi."sale_price") AS "Total_Revenue_June",
    SUM(oi."sale_price" - p."cost") AS "Total_Profit_June"
  FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
  JOIN
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    ON oi."product_id" = p."id"
  WHERE
    TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1e6), 'YYYY-MM') = '2019-06'
  GROUP BY
    p."category"
)
SELECT
  md."Month",
  md."Product_Category",
  md."Total_Orders",
  md."Total_Revenue",
  md."Total_Profit",
  ROUND(
    100 * (md."Total_Orders" - jd."Total_Orders_June") / NULLIF(jd."Total_Orders_June", 0),
    2
  ) AS "MoM_Growth_Orders(%)",
  ROUND(
    100 * (md."Total_Revenue" - jd."Total_Revenue_June") / NULLIF(jd."Total_Revenue_June", 0),
    2
  ) AS "MoM_Growth_Revenue(%)",
  ROUND(
    100 * (md."Total_Profit" - jd."Total_Profit_June") / NULLIF(jd."Total_Profit_June", 0),
    2
  ) AS "MoM_Growth_Profit(%)"
FROM
  monthly_data md
LEFT JOIN
  june_data jd
  ON md."Product_Category" = jd."Product_Category"
WHERE
  md."Month" >= '2019-07' AND md."Month" <= '2019-12'
ORDER BY
  md."Month",
  md."Product_Category";