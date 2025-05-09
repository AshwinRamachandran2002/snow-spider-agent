-- 1)  Calculate the weighted score for every musical style
-- 2)  Find the average of those scores
-- 3)  Return each style’s score together with its absolute difference from the average
WITH
/*----------------------------------------------------------
  Step-1 :  Sum up weighted points for every style
----------------------------------------------------------*/
STYLE_SCORES AS (
    SELECT
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                 WHEN 1 THEN 3     -- first choice  → 3 points
                 WHEN 2 THEN 2     -- second choice → 2 points
                 WHEN 3 THEN 1     -- third choice  → 1 point
                 ELSE 0
            END
        ) AS "TotalWeightedScore"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    WHERE "PreferenceSeq" IN (1, 2, 3)          -- keep only ranked choices
    GROUP BY "StyleID"
),
/*----------------------------------------------------------
  Step-2 :  Overall average of the style scores
----------------------------------------------------------*/
AVG_SCORE AS (
    SELECT AVG("TotalWeightedScore") AS "AvgScore"
    FROM STYLE_SCORES
)

/*----------------------------------------------------------
  Step-3 :  Final result with absolute difference
----------------------------------------------------------*/
SELECT
    s."StyleID",
    m."StyleName",
    s."TotalWeightedScore",
    a."AvgScore",
    ABS(s."TotalWeightedScore" - a."AvgScore")  AS "AbsDiffFromAvg"
FROM STYLE_SCORES       s
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES m
       ON s."StyleID" = m."StyleID"
CROSS JOIN AVG_SCORE    a
ORDER BY s."TotalWeightedScore" DESC NULLS LAST;