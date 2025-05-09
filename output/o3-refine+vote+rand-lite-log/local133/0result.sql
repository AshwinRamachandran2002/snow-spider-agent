WITH RankedScores AS (
    /* Assign points based on the ranking position */
    SELECT
        "StyleID",
        CASE "PreferenceSeq"
             WHEN 1 THEN 3
             WHEN 2 THEN 2
             WHEN 3 THEN 1
             ELSE 0
        END AS points
    FROM "Musical_Preferences"
    WHERE "PreferenceSeq" IN (1,2,3)
),
StyleTotals AS (
    /* Sum the points for each musical style */
    SELECT
        ms."StyleID",
        ms."StyleName",
        SUM(rs.points) AS TotalWeightedScore
    FROM RankedScores rs
    JOIN "Musical_Styles" ms
         ON ms."StyleID" = rs."StyleID"
    GROUP BY
        ms."StyleID",
        ms."StyleName"
),
AvgScore AS (
    /* Compute the average weighted score across all ranked styles */
    SELECT AVG("TotalWeightedScore") AS AvgWeightedScore
    FROM StyleTotals
)
SELECT
    st."StyleID",
    st."StyleName",
    st."TotalWeightedScore",
    a.AvgWeightedScore,
    ABS(st."TotalWeightedScore" - a.AvgWeightedScore) AS AbsDifference
FROM StyleTotals st
CROSS JOIN AvgScore a
ORDER BY
    AbsDifference DESC,
    st."StyleID";