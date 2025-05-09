WITH Weighted AS (
    SELECT 
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                WHEN 1 THEN 3   -- 1st‑place vote
                WHEN 2 THEN 2   -- 2nd‑place vote
                WHEN 3 THEN 1   -- 3rd‑place vote
                ELSE 0
            END
        ) AS "WeightedScore"
    FROM "Musical_Preferences"
    GROUP BY "StyleID"
),
AvgScore AS (
    SELECT AVG("WeightedScore") AS "AvgWeightedScore"
    FROM   Weighted
)
SELECT
    w."StyleID",
    w."WeightedScore",
    ABS(w."WeightedScore" - a."AvgWeightedScore") AS "AbsDiff"
FROM   Weighted AS w
CROSS  JOIN AvgScore AS a
ORDER  BY w."StyleID";