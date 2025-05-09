WITH weights AS (
    SELECT
        mp."StyleID",
        SUM(
            CASE mp."PreferenceSeq"
                WHEN 1 THEN 3
                WHEN 2 THEN 2
                WHEN 3 THEN 1
                ELSE 0
            END
        ) AS total_weighted_score
    FROM "Musical_Preferences" AS mp
    GROUP BY mp."StyleID"
),
avg_score AS (
    SELECT AVG(total_weighted_score) AS avg_score
    FROM weights
)
SELECT
    ms."StyleName"                                                       AS musical_style,
    w.total_weighted_score                                               AS total_weighted_score,
    ROUND(ABS(w.total_weighted_score - a.avg_score), 4)                  AS abs_diff_from_avg
FROM weights           AS w
CROSS JOIN avg_score    AS a
JOIN "Musical_Styles"  AS ms ON ms."StyleID" = w."StyleID"
ORDER BY w.total_weighted_score DESC,
         ms."StyleName";