SELECT
    t."boroname" AS Borough,
    COUNT(*) AS Number_of_Trees,
    AVG(i."Estimate_Mean_income") AS Average_Mean_Income
FROM
    "trees" AS t
    JOIN "income_trees" AS i ON t."zipcode" = i."zipcode"
WHERE
    t."boroname" IS NOT NULL AND TRIM(t."boroname") <> ''
    AND t."zipcode" IS NOT NULL AND TRIM(t."zipcode") <> ''
    AND i."Estimate_Median_income" > 0
    AND i."Estimate_Mean_income" > 0
GROUP BY
    t."boroname"
ORDER BY
    COUNT(*) DESC
LIMIT 3;