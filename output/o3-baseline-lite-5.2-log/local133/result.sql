WITH style_scores AS (
    SELECT
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                WHEN 1 THEN 3
                WHEN 2 THEN 2
                WHEN 3 THEN 1
                ELSE 0
            END
        ) AS total_weighted_score
    FROM "Musical_Preferences"
    WHERE "PreferenceSeq" IN (1,2,3)
    GROUP BY "StyleID"
),
avg_score AS (
    SELECT AVG(total_weighted_score * 1.0) AS avg_weighted_score
    FROM style_scores
)
SELECT
    ss."StyleID",
    ss.total_weighted_score,
    ROUND(ABS(ss.total_weighted_score - a.avg_weighted_score), 4) AS difference_from_avg
FROM style_scores AS ss
CROSS JOIN avg_score AS a
ORDER BY ss."StyleID";