WITH Scores AS (
    SELECT 
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                 WHEN 1 THEN 3   -- first-choice → 3 points
                 WHEN 2 THEN 2   -- second-choice → 2 points
                 WHEN 3 THEN 1   -- third-choice  → 1 point
            END
        ) AS "WeightedScore"
    FROM "Musical_Preferences"
    GROUP BY "StyleID"
),
AvgScore AS (
    SELECT AVG("WeightedScore") AS "AvgWeightedScore"
    FROM Scores
)
SELECT
    ms."StyleID",
    ms."StyleName",
    s."WeightedScore",
    ABS(s."WeightedScore" - a."AvgWeightedScore") AS "AbsDifferenceFromAvg"
FROM Scores        AS s
CROSS JOIN AvgScore AS a     -- single‐row result to supply the average
JOIN "Musical_Styles" ms
  ON ms."StyleID" = s."StyleID"
ORDER BY s."WeightedScore" DESC;