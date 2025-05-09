WITH style_scores AS (
    /* 1. Calculate the weighted score for every style that appears in Musical_Preferences */
    SELECT
        StyleID,
        SUM(
            CASE PreferenceSeq
                WHEN 1 THEN 3    -- 1st‑choice  → 3 points
                WHEN 2 THEN 2    -- 2nd‑choice  → 2 points
                WHEN 3 THEN 1    -- 3rd‑choice  → 1 point
                ELSE 0
            END
        ) AS total_weighted_score
    FROM Musical_Preferences
    GROUP BY StyleID
),
avg_scores AS (
    /* 2. Get the average of those total weighted scores */
    SELECT AVG(total_weighted_score) AS avg_score
    FROM style_scores
)
SELECT
    ss.StyleID,
    ms.StyleName,
    ss.total_weighted_score,
    ROUND(ABS(ss.total_weighted_score - a.avg_score), 4) AS abs_difference_from_avg
FROM style_scores ss
JOIN avg_scores a
LEFT JOIN Musical_Styles ms ON ms.StyleID = ss.StyleID
ORDER BY ss.total_weighted_score DESC, ss.StyleID;