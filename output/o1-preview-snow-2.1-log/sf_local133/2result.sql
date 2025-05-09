WITH style_scores AS (
    SELECT s."StyleName",
           SUM(
             CASE p."PreferenceSeq"
               WHEN 1 THEN 3
               WHEN 2 THEN 2
               WHEN 3 THEN 1
               ELSE 0
             END
           ) AS "TotalWeightedScore"
    FROM "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_PREFERENCES" p
    JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_STYLES" s
      ON p."StyleID" = s."StyleID"
    GROUP BY s."StyleName"
),
average_score AS (
    SELECT AVG("TotalWeightedScore") AS "AverageScore" FROM style_scores
)
SELECT
    style_scores."StyleName",
    style_scores."TotalWeightedScore",
    ROUND(ABS(style_scores."TotalWeightedScore" - average_score."AverageScore"), 4) AS "AbsoluteDifferenceFromAverage"
FROM style_scores, average_score
ORDER BY style_scores."StyleName";