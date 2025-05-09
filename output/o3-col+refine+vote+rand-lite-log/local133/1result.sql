WITH ScorePerStyle AS (
    SELECT  mp."StyleID",
            3 * SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) +
            2 * SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) +
            1 * SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "TotalWeightedScore"
    FROM    "Musical_Preferences" AS mp
    GROUP BY mp."StyleID"
),
AvgScore AS (
    SELECT AVG("TotalWeightedScore") AS "AvgWeightedScore"
    FROM   ScorePerStyle
)
SELECT  s."StyleID",
        ms."StyleName",
        s."TotalWeightedScore",
        ABS(s."TotalWeightedScore" - a."AvgWeightedScore") AS "AbsDiffFromAverage"
FROM    ScorePerStyle AS s
CROSS JOIN AvgScore     AS a
LEFT  JOIN "Musical_Styles" AS ms
       ON ms."StyleID" = s."StyleID"
ORDER BY s."StyleID";