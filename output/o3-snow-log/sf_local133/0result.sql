WITH STYLE_SCORES AS (
    /* 1.  Calculate the weighted score for each style */
    SELECT
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                WHEN 1 THEN 3      /* first-choice = 3 points */
                WHEN 2 THEN 2      /* second-choice = 2 points */
                WHEN 3 THEN 1      /* third-choice  = 1 point  */
                ELSE 0
            END
        ) AS TOTAL_WEIGHTED_SCORE
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    WHERE "PreferenceSeq" IN (1,2,3)               -- only ranked choices
    GROUP BY "StyleID"
),
AVG_SCORE AS (
    /* 2.  Compute the average of the style totals */
    SELECT AVG(TOTAL_WEIGHTED_SCORE) AS AVG_TOTAL_SCORE
    FROM STYLE_SCORES
)
SELECT
    ss."StyleID",
    ms."StyleName",
    ss.TOTAL_WEIGHTED_SCORE,
    ABS(ss.TOTAL_WEIGHTED_SCORE - a.AVG_TOTAL_SCORE) AS ABS_DIFF_FROM_AVG
FROM STYLE_SCORES ss
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES ms
       ON ss."StyleID" = ms."StyleID"
CROSS JOIN AVG_SCORE a
ORDER BY ABS_DIFF_FROM_AVG DESC NULLS LAST;