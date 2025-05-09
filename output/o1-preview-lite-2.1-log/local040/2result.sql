WITH tree_counts AS (
    SELECT "boroname", COUNT(*) AS "Trees_Count"
    FROM "trees"
    GROUP BY "boroname"
),
avg_incomes AS (
    SELECT z."boroname", ROUND(AVG(i."Estimate_Mean_income"), 4) AS "Average_Mean_Income"
    FROM (
        SELECT DISTINCT "zipcode", "boroname"
        FROM "trees"
        WHERE "zipcode" IS NOT NULL AND TRIM("zipcode") != ''
    ) AS z
    JOIN "income_trees" AS i ON z."zipcode" = i."zipcode"
    WHERE i."Estimate_Mean_income" > 0 AND i."Estimate_Median_income" > 0
    GROUP BY z."boroname"
)
SELECT t."boroname" AS "Borough", t."Trees_Count", a."Average_Mean_Income"
FROM tree_counts t
JOIN avg_incomes a ON t."boroname" = a."boroname"
ORDER BY t."Trees_Count" DESC
LIMIT 3;