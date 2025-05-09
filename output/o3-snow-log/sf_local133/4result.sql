WITH style_scores AS (               -- 1) total weighted score per style
    SELECT
        mp."StyleID",
        SUM(
            CASE mp."PreferenceSeq"
                WHEN 1 THEN 3           -- 3 pts for 1st choice
                WHEN 2 THEN 2           -- 2 pts for 2nd choice
                WHEN 3 THEN 1           -- 1 pt  for 3rd choice
                ELSE 0
            END
        ) AS total_score
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES" mp
    WHERE mp."PreferenceSeq" IN (1,2,3)
    GROUP BY mp."StyleID"
)

SELECT
    ss."StyleID",
    ms."StyleName",
    ss.total_score                            AS "TotalWeightedScore",
    ABS(ss.total_score - avgtab.avg_total)    AS "DifferenceFromAverage"
FROM style_scores ss
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_STYLES" ms
       ON ss."StyleID" = ms."StyleID"
CROSS JOIN (SELECT AVG(total_score) AS avg_total FROM style_scores) avgtab
ORDER BY ss."StyleID";