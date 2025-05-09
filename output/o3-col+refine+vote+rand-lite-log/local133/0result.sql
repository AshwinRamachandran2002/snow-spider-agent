WITH weighted_scores AS (
    /* 1.  Calculate the weighted total for every style that was ranked */
    SELECT 
        mp."StyleID",
        SUM(
            CASE mp."PreferenceSeq"
                WHEN 1 THEN 3     -- first-choice = 3 points
                WHEN 2 THEN 2     -- second-choice = 2 points
                WHEN 3 THEN 1     -- third-choice  = 1 point
            END
        ) AS "TotalScore"
    FROM "Musical_Preferences" AS mp
    GROUP BY mp."StyleID"
),
avg_score AS (
    /* 2.  Compute the overall average of those totals */
    SELECT AVG("TotalScore") AS "AvgScore"
    FROM   weighted_scores
)
SELECT
    ms."StyleName",
    ws."TotalScore",
    ABS(ws."TotalScore" - avg_score."AvgScore") AS "ScoreDiff"
FROM   weighted_scores AS ws
JOIN   avg_score                     /* cross-join – single-row result */
JOIN   "Musical_Styles" AS ms
       ON ms."StyleID" = ws."StyleID"
ORDER BY ms."StyleName";