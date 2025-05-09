WITH ScorePerStyle AS (
    SELECT
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                WHEN 1 THEN 3     -- 1st-choice vote
                WHEN 2 THEN 2     -- 2nd-choice vote
                WHEN 3 THEN 1     -- 3rd-choice vote
                ELSE 0
            END
        ) AS "WeightedScore"
    FROM "Musical_Preferences"
    GROUP BY "StyleID"
),
AverageScore AS (
    SELECT AVG("WeightedScore") AS "AvgScore"
    FROM ScorePerStyle
)
SELECT
    ms."StyleID",
    ms."StyleName",
    s."WeightedScore",
    ABS(s."WeightedScore" - a."AvgScore") AS "AbsoluteDifference"
FROM ScorePerStyle          s
JOIN "Musical_Styles"        ms ON ms."StyleID" = s."StyleID"
CROSS JOIN AverageScore      a
ORDER BY "AbsoluteDifference" DESC,
         ms."StyleID";