SELECT t."boroname" AS "Borough",
       COUNT(*) AS "Trees_Count",
       AVG(CASE WHEN it."Estimate_Mean_income" > 0 AND it."Estimate_Median_income" > 0 THEN it."Estimate_Mean_income" END) AS "Average_Mean_Income"
FROM "trees" t
LEFT JOIN "income_trees" it ON t."zipcode" = it."zipcode"
GROUP BY t."boroname"
ORDER BY COUNT(*) DESC
LIMIT 3;