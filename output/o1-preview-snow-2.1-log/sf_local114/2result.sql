WITH Regional_Totals AS (
    SELECT r."name" AS "Region_Name",
           COUNT(o."id") AS "Number_of_Orders",
           ROUND(SUM(o."total_amt_usd"), 4) AS "Total_Sales_Amount"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ORDERS o
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ACCOUNTS a
      ON o."account_id" = a."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_SALES_REPS s
      ON a."sales_rep_id" = s."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_REGION r
      ON s."region_id" = r."id"
    GROUP BY r."name"
),
Top_Sales_Reps AS (
    SELECT t."Region_Name",
           t."Sales_Rep_Name" AS "Top_Sales_Representative_Name",
           t."Sales_Rep_Total_Sales_Amount" AS "Top_Sales_Amount"
    FROM (
        SELECT r."name" AS "Region_Name",
               s."name" AS "Sales_Rep_Name",
               ROUND(SUM(o."total_amt_usd"), 4) AS "Sales_Rep_Total_Sales_Amount",
               ROW_NUMBER() OVER (
                   PARTITION BY r."name"
                   ORDER BY SUM(o."total_amt_usd") DESC NULLS LAST
               ) AS "Rep_Rank"
        FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ORDERS o
        JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ACCOUNTS a
          ON o."account_id" = a."id"
        JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_SALES_REPS s
          ON a."sales_rep_id" = s."id"
        JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_REGION r
          ON s."region_id" = r."id"
        GROUP BY r."name", s."name"
    ) t
    WHERE t."Rep_Rank" = 1
)
SELECT rt."Region_Name",
       rt."Number_of_Orders",
       rt."Total_Sales_Amount",
       tsr."Top_Sales_Representative_Name",
       tsr."Top_Sales_Amount"
FROM Regional_Totals rt
JOIN Top_Sales_Reps tsr
  ON rt."Region_Name" = tsr."Region_Name"
ORDER BY rt."Region_Name";