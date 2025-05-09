WITH regional_sales AS (
  SELECT
    r."name" AS "Region_Name",
    COUNT(o."id") AS "Number_of_Orders",
    ROUND(SUM(o."total_amt_usd"), 4) AS "Total_Sales_Amount"
  FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ORDERS" o
  JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ACCOUNTS" a
    ON o."account_id" = a."id"
  JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_SALES_REPS" sr
    ON a."sales_rep_id" = sr."id"
  JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_REGION" r
    ON sr."region_id" = r."id"
  GROUP BY r."name"
),
sales_rep_sales AS (
  SELECT
    r."name" AS "Region_Name",
    sr."name" AS "Sales_Rep_Name",
    ROUND(SUM(o."total_amt_usd"), 4) AS "Sales_Amount",
    ROW_NUMBER() OVER (
      PARTITION BY r."name" 
      ORDER BY SUM(o."total_amt_usd") DESC NULLS LAST
    ) AS "Rank"
  FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ORDERS" o
  JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ACCOUNTS" a
    ON o."account_id" = a."id"
  JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_SALES_REPS" sr
    ON a."sales_rep_id" = sr."id"
  JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_REGION" r
    ON sr."region_id" = r."id"
  GROUP BY r."name", sr."name"
)
SELECT
  rs."Region_Name",
  rs."Number_of_Orders",
  rs."Total_Sales_Amount",
  srs."Sales_Rep_Name" AS "Top_Sales_Representative_Name",
  srs."Sales_Amount" AS "Top_Sales_Amount"
FROM regional_sales rs
JOIN sales_rep_sales srs
  ON rs."Region_Name" = srs."Region_Name" AND srs."Rank" = 1
ORDER BY rs."Region_Name";