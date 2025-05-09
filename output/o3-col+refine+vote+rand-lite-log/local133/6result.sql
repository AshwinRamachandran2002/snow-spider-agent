WITH style_scores AS (
    -- 1) Total weighted score for each musical style
    SELECT mp."StyleID",
           SUM(
               CASE mp."PreferenceSeq"
                    WHEN 1 THEN 3   -- 1st choice = 3 points
                    WHEN 2 THEN 2   -- 2nd choice = 2 points
                    WHEN 3 THEN 1   -- 3rd choice = 1 point
                    ELSE 0
               END
           ) AS "WeightedScore"
    FROM "Musical_Preferences" AS mp
    GROUP BY mp."StyleID"
),
avg_score AS (
    -- 2) Average weighted score across all ranked styles
    SELECT AVG("WeightedScore") AS "AvgScore"
    FROM style_scores
)
-- 3) Final result: score per style and absolute difference from the average
SELECT ss."StyleID",
       ms."StyleName",
       ss."WeightedScore",
       ROUND(ABS(ss."WeightedScore" - a."AvgScore"), 4) AS "AbsDiffFromAvg"
FROM   style_scores  AS ss
CROSS  JOIN avg_score AS a
LEFT   JOIN "Musical_Styles" AS ms
       ON ms."StyleID" = ss."StyleID"
ORDER  BY ss."WeightedScore" DESC;