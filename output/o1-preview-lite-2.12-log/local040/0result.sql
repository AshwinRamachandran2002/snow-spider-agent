SELECT t."boroname", COUNT(*) AS "Number_of_Trees", AVG(i."Estimate_Mean_income") AS "Average_Mean_Income"
FROM "trees" t
JOIN "income_trees" i ON t."zipcode" = i."zipcode"
WHERE t."boroname" IS NOT NULL AND t."boroname" != ''
  AND i."Estimate_Median_income" > 0
  AND i."Estimate_Mean_income" > 0
GROUP BY t."boroname"
ORDER BY "Number_of_Trees" DESC
LIMIT 3;