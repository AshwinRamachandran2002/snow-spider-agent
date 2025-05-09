WITH regional_sales AS (
  SELECT
    r."name" AS "Region_Name",
    COUNT(o."id") AS "Number_of_Orders",
    ROUND(SUM(o."total_amt_usd"), 4) AS "Total_Sales_Amount"
  FROM
    EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ORDERS o
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ACCOUNTS a
      ON o."account_id" = a."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_SALES_REPS s
      ON a."sales_rep_id" = s."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_REGION r
      ON s."region_id" = r."id"
  GROUP BY
    r."name"
),
sales_rep_totals AS (
  SELECT
    r."name" AS "Region_Name",
    s."name" AS "Sales_Rep_Name",
    ROUND(SUM(o."total_amt_usd"), 4) AS "Sales_Amount",
    ROW_NUMBER() OVER (
      PARTITION BY r."name"
      ORDER BY SUM(o."total_amt_usd") DESC NULLS LAST
    ) AS "Rep_Rank"
  FROM
    EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ORDERS o
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ACCOUNTS a
      ON o."account_id" = a."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_SALES_REPS s
      ON a."sales_rep_id" = s."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_REGION r
      ON s."region_id" = r."id"
  GROUP BY
    r."name",
    s."name"
)
SELECT
  rs."Region_Name",
  rs."Number_of_Orders",
  rs."Total_Sales_Amount",
  st."Sales_Rep_Name" AS "Top_Sales_Representative_Name",
  st."Sales_Amount" AS "Top_Sales_Amount"
FROM
  regional_sales rs
  JOIN sales_rep_totals st
    ON rs."Region_Name" = st."Region_Name" AND st."Rep_Rank" = 1
ORDER BY
  rs."Region_Name";