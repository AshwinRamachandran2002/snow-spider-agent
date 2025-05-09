SELECT
    mp.StyleID,
    ms.StyleName,
    SUM(CASE mp.PreferenceSeq
            WHEN 1 THEN 3
            WHEN 2 THEN 2
            WHEN 3 THEN 1
            ELSE 0
        END)                                                      AS TotalWeightedScore,
    avg_tbl.AverageTotalWeightedScore                             AS AverageScore,
    ABS(SUM(CASE mp.PreferenceSeq
                WHEN 1 THEN 3
                WHEN 2 THEN 2
                WHEN 3 THEN 1
                ELSE 0
            END) - avg_tbl.AverageTotalWeightedScore)             AS AbsDifference
FROM Musical_Preferences AS mp
JOIN Musical_Styles      AS ms   ON ms.StyleID = mp.StyleID
/* one-row sub‑query that holds the overall average */
CROSS JOIN (
    SELECT AVG(StyleTotal) AS AverageTotalWeightedScore
    FROM (
        SELECT SUM(CASE PreferenceSeq
                       WHEN 1 THEN 3
                       WHEN 2 THEN 2
                       WHEN 3 THEN 1
                       ELSE 0
                   END) AS StyleTotal
        FROM Musical_Preferences
        GROUP BY StyleID
    )
) AS avg_tbl
GROUP BY mp.StyleID, ms.StyleName;