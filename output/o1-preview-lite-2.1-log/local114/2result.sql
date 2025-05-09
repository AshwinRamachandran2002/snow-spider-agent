WITH
  Total_Sales_Per_Region AS (
    SELECT
      r."name" AS Region,
      COUNT(o."id") AS Number_of_Orders,
      SUM(o."total_amt_usd") AS Total_Sales_Amount
    FROM
      "web_orders" o
      JOIN "web_accounts" a ON o."account_id" = a."id"
      JOIN "web_sales_reps" s ON a."sales_rep_id" = s."id"
      JOIN "web_region" r ON s."region_id" = r."id"
    GROUP BY
      r."name"
  ),
  Sales_Per_Rep AS (
    SELECT
      r."name" AS Region,
      s."name" AS Sales_Rep_Name,
      SUM(o."total_amt_usd") AS Sales_Rep_Total_Sales
    FROM
      "web_orders" o
      JOIN "web_accounts" a ON o."account_id" = a."id"
      JOIN "web_sales_reps" s ON a."sales_rep_id" = s."id"
      JOIN "web_region" r ON s."region_id" = r."id"
    GROUP BY
      r."name",
      s."name"
  ),
  Top_Sales_Reps AS (
    SELECT
      spr.Region,
      spr.Sales_Rep_Name,
      spr.Sales_Rep_Total_Sales
    FROM
      Sales_Per_Rep spr
      JOIN (
        SELECT
          Region,
          MAX(Sales_Rep_Total_Sales) AS Max_Sales
        FROM
          Sales_Per_Rep
        GROUP BY
          Region
      ) ms ON spr.Region = ms.Region AND spr.Sales_Rep_Total_Sales = ms.Max_Sales
  )
SELECT
  tspr.Region,
  tspr.Number_of_Orders,
  ROUND(tspr.Total_Sales_Amount, 4) AS Total_Sales_Amount,
  tsr.Sales_Rep_Name AS Top_Sales_Rep_Name,
  ROUND(tsr.Sales_Rep_Total_Sales, 4) AS Top_Sales_Rep_Sales_Amount
FROM
  Total_Sales_Per_Region tspr
  JOIN Top_Sales_Reps tsr ON tspr.Region = tsr.Region
ORDER BY
  tspr.Region;