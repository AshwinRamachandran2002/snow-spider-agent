WITH per_style_score AS (
    /* 1.  Calculate the weighted score for each style */
    SELECT
        StyleID,
        SUM(
            CASE PreferenceSeq
                 WHEN 1 THEN 3     -- first choice
                 WHEN 2 THEN 2     -- second choice
                 WHEN 3 THEN 1     -- third choice
                 ELSE 0
            END
        ) AS total_score
    FROM Musical_Preferences
    WHERE PreferenceSeq IN (1, 2, 3)   -- only 1st‑3rd choices matter
    GROUP BY StyleID
),
avg_score AS (
    /* 2.  Average of those total scores */
    SELECT AVG(total_score) AS avg_total_score
    FROM per_style_score
)
SELECT
    ps.StyleID,
    ms.StyleName,
    ps.total_score,
    ABS(ps.total_score - a.avg_total_score) AS abs_diff_from_avg
FROM per_style_score ps
LEFT JOIN Musical_Styles ms ON ms.StyleID = ps.StyleID   -- style name (optional)
CROSS JOIN avg_score a                                    -- same avg for every row
ORDER BY ps.StyleID;