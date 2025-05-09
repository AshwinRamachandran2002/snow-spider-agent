WITH StyleScores AS (
    SELECT ms."StyleName",
           SUM(
               CASE mp."PreferenceSeq"
                   WHEN 1 THEN 3
                   WHEN 2 THEN 2
                   WHEN 3 THEN 1
                   ELSE 0
               END
           ) AS "TotalWeightedScore"
    FROM "Musical_Preferences" mp
    JOIN "Musical_Styles" ms ON mp."StyleID" = ms."StyleID"
    GROUP BY ms."StyleName"
),
AverageScore AS (
    SELECT AVG("TotalWeightedScore") AS "AverageScore"
    FROM StyleScores
)
SELECT s."StyleName",
       s."TotalWeightedScore",
       ROUND(ABS(s."TotalWeightedScore" - a."AverageScore"), 4) AS "AbsoluteDifferenceFromAverage"
FROM StyleScores s
CROSS JOIN AverageScore a
ORDER BY s."StyleName";