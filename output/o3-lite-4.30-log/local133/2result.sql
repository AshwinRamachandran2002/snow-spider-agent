WITH scores AS (
    SELECT
        mp."StyleID",
        SUM(
            CASE mp."PreferenceSeq"
                WHEN 1 THEN 3
                WHEN 2 THEN 2
                WHEN 3 THEN 1
            END
        ) AS total_weighted_score
    FROM "Musical_Preferences" AS mp
    GROUP BY mp."StyleID"
),
avg_val AS (
    SELECT AVG(total_weighted_score) AS avg_score
    FROM scores
)
SELECT
    ms."StyleName"                            AS musical_style,
    s.total_weighted_score,
    ROUND(ABS(s.total_weighted_score - a.avg_score), 4) AS abs_diff_from_avg
FROM scores AS s
JOIN "Musical_Styles" AS ms ON ms."StyleID" = s."StyleID"
JOIN avg_val AS a
ORDER BY abs_diff_from_avg DESC, musical_style;