WITH style_scores AS (
    /* 1.  Compute the 3-2-1 weighted total for every style that was ranked */
    SELECT mp."StyleID",
           3 * SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) +
           2 * SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) +
           1 * SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END)     AS TotalWeightedScore
    FROM "Musical_Preferences" AS mp
    GROUP BY mp."StyleID"
),
avg_score AS (
    /* 2.  Average of those weighted totals */
    SELECT AVG(TotalWeightedScore) AS AvgTotalWeightedScore
    FROM style_scores
)
SELECT ms."StyleID",
       ms."StyleName",
       ss."TotalWeightedScore",
       avg_score."AvgTotalWeightedScore",
       ABS(ss."TotalWeightedScore" - avg_score."AvgTotalWeightedScore") AS ScoreDifference
FROM style_scores AS ss
JOIN "Musical_Styles" AS ms
  ON ms."StyleID" = ss."StyleID"
CROSS JOIN avg_score
ORDER BY ScoreDifference DESC,
         ms."StyleName";