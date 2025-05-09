WITH style_scores AS (
    /* 1.  Calculate the weighted score for every style that appears in MUSICAL_PREFERENCES */
    SELECT
        "StyleID",
        SUM(
            CASE 
                WHEN "PreferenceSeq" = 1 THEN 3     -- 1st choice
                WHEN "PreferenceSeq" = 2 THEN 2     -- 2nd choice
                WHEN "PreferenceSeq" = 3 THEN 1     -- 3rd choice
                ELSE 0                              -- ignore any other values
            END
        ) AS total_weighted_score
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    WHERE "PreferenceSeq" IN (1, 2, 3)              -- consider only the three ranked positions
    GROUP BY "StyleID"
),
avg_score AS (
    /* 2.  Compute the average of those total weighted scores */
    SELECT AVG(total_weighted_score) AS avg_weighted_score
    FROM style_scores
)

SELECT
    ss."StyleID",
    ms."StyleName",
    ss.total_weighted_score,
    avg_score.avg_weighted_score,
    ABS(ss.total_weighted_score - avg_score.avg_weighted_score) AS abs_difference
FROM style_scores ss
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES ms
       ON ss."StyleID" = ms."StyleID"
CROSS JOIN avg_score
ORDER BY abs_difference DESC NULLS LAST;