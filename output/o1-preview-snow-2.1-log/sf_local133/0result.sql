WITH StyleScores AS (
    SELECT "StyleID",
           SUM(CASE WHEN "PreferenceSeq" = 1 THEN 3
                    WHEN "PreferenceSeq" = 2 THEN 2
                    WHEN "PreferenceSeq" = 3 THEN 1
               END) AS TotalWeightedScore
    FROM "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_PREFERENCES"
    GROUP BY "StyleID"
),
AverageScore AS (
    SELECT AVG(TotalWeightedScore) AS AvgScore
    FROM StyleScores
)
SELECT ms."StyleName",
       ss.TotalWeightedScore,
       ROUND(ABS(ss.TotalWeightedScore - a.AvgScore), 4) AS "AbsoluteDifferenceFromAverage"
FROM StyleScores ss
JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_STYLES" ms
  ON ss."StyleID" = ms."StyleID"
CROSS JOIN AverageScore a
ORDER BY ms."StyleName";