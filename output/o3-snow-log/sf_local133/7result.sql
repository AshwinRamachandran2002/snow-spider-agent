WITH weighted_scores AS (          -- 1. total weighted score per style
    SELECT 
        "StyleID",
        SUM(CASE 
                WHEN "PreferenceSeq" = 1 THEN 3      -- 1st choice
                WHEN "PreferenceSeq" = 2 THEN 2      -- 2nd choice
                WHEN "PreferenceSeq" = 3 THEN 1      -- 3rd choice
                ELSE 0
            END) AS total_weighted_score
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    WHERE "PreferenceSeq" IN (1,2,3)                 -- only ranked choices
    GROUP BY "StyleID"
), avg_score AS (                                    -- 2. average of totals
    SELECT AVG(total_weighted_score) AS avg_total_weighted_score
    FROM weighted_scores
)
SELECT 
    ws."StyleID",
    ms."StyleName",
    ws.total_weighted_score,
    a.avg_total_weighted_score,
    ABS(ws.total_weighted_score - a.avg_total_weighted_score) AS score_difference
FROM weighted_scores              ws
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES  ms
       ON ws."StyleID" = ms."StyleID"
CROSS JOIN avg_score              a
ORDER BY score_difference DESC NULLS LAST;