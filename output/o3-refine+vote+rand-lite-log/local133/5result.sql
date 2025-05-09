/* 1.  Calculate the weighted score for every style that has at least one ranking
   2.  Find the average of those weighted scores
   3.  Return each style’s score together with the absolute difference from the average
*/

SELECT  ms."StyleID",
        ms."StyleName",
        ws.TotalWeightedScore,
        ROUND(ABS(ws.TotalWeightedScore - avg_tab.AvgWeightedScore), 4) AS AbsDiffFromAverage
FROM    Musical_Styles               AS ms
JOIN    (   /* step‑1: weighted score per style */
            SELECT  "StyleID",
                    SUM(
                        CASE "PreferenceSeq"
                             WHEN 1 THEN 3        -- first choice
                             WHEN 2 THEN 2        -- second choice
                             WHEN 3 THEN 1        -- third choice
                             ELSE 0
                        END
                    ) AS TotalWeightedScore
            FROM    Musical_Preferences
            WHERE   "PreferenceSeq" IN (1,2,3)
            GROUP BY "StyleID"
        )                          AS ws
        ON ms."StyleID" = ws."StyleID"
CROSS JOIN
        (   /* step‑2: average of all weighted scores */
            SELECT  AVG(TotalWeightedScore) AS AvgWeightedScore
            FROM   ( SELECT "StyleID",
                            SUM(
                                CASE "PreferenceSeq"
                                     WHEN 1 THEN 3
                                     WHEN 2 THEN 2
                                     WHEN 3 THEN 1
                                     ELSE 0
                                END
                            ) AS TotalWeightedScore
                     FROM   Musical_Preferences
                     WHERE  "PreferenceSeq" IN (1,2,3)
                     GROUP BY "StyleID"
                   )
        )                          AS avg_tab
ORDER BY ws.TotalWeightedScore DESC,
         ms."StyleID";