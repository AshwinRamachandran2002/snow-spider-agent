SELECT t."boroname" AS "Borough",
       COUNT(t."tree_id") AS "Number_of_Trees",
       ROUND(AVG(CASE WHEN i."Estimate_Mean_income" > 0 AND i."Estimate_Median_income" > 0
                      THEN i."Estimate_Mean_income" END), 4) AS "Average_Mean_Income"
FROM MODERN_DATA.MODERN_DATA.TREES t
LEFT JOIN MODERN_DATA.MODERN_DATA.INCOME_TREES i
  ON t."zipcode" = i."zipcode"
GROUP BY t."boroname"
ORDER BY COUNT(t."tree_id") DESC NULLS LAST
LIMIT 3;