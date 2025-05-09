WITH style_scores AS (               -- 1. total weighted score per style
    SELECT
        mp."StyleID",
        SUM(
            CASE mp."PreferenceSeq"
                WHEN 1 THEN 3          -- first choice  = 3 points
                WHEN 2 THEN 2          -- second choice = 2 points
                WHEN 3 THEN 1          -- third choice  = 1 point
                ELSE 0
            END
        ) AS total_score
    FROM "Musical_Preferences" mp
    GROUP BY mp."StyleID"
),
avg_score AS (                       -- 2. average of those totals
    SELECT AVG(total_score) AS avg_total_score
    FROM style_scores
)
SELECT                               -- 3. result with absolute difference
    ss."StyleID",
    ms."StyleName",
    ss.total_score,
    avg_score.avg_total_score        AS average_total_score,
    ABS(ss.total_score - avg_score.avg_total_score) AS score_difference
FROM style_scores ss
JOIN avg_score ON 1=1
LEFT JOIN "Musical_Styles" ms ON ms."StyleID" = ss."StyleID"
ORDER BY ss.total_score DESC, ss."StyleID";