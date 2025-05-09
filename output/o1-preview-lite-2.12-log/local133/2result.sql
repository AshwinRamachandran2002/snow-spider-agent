SELECT ms."StyleName",
       TotalScores."TotalWeightedScore",
       ROUND(ABS(TotalScores."TotalWeightedScore" - AverageScores."AverageScore"), 4) AS "AbsoluteDifferenceFromAverage"
FROM
(
    SELECT "StyleID",
           SUM(
               CASE "PreferenceSeq"
                   WHEN 1 THEN 3
                   WHEN 2 THEN 2
                   WHEN 3 THEN 1
                   ELSE 0
               END
           ) AS "TotalWeightedScore"
    FROM "Musical_Preferences"
    GROUP BY "StyleID"
) AS TotalScores
CROSS JOIN
(
    SELECT AVG("TotalWeightedScore") AS "AverageScore" FROM (
        SELECT "StyleID",
               SUM(
                   CASE "PreferenceSeq"
                       WHEN 1 THEN 3
                       WHEN 2 THEN 2
                       WHEN 3 THEN 1
                       ELSE 0
                   END
               ) AS "TotalWeightedScore"
        FROM "Musical_Preferences"
        GROUP BY "StyleID"
    ) AS StyleScores
) AS AverageScores
JOIN "Musical_Styles" ms ON TotalScores."StyleID" = ms."StyleID";