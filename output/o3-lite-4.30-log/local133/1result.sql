WITH score_per_style AS (
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
    WHERE mp."PreferenceSeq" IN (1,2,3)
    GROUP BY mp."StyleID"
),
avg_score AS (
    SELECT AVG(total_weighted_score) AS avg_score
    FROM score_per_style
)
SELECT
    ms."StyleName"                                   AS musical_style,
    s.total_weighted_score,
    ROUND(ABS(s.total_weighted_score - a.avg_score),4) AS abs_diff_from_avg
FROM score_per_style AS s
JOIN "Musical_Styles"  AS ms ON ms."StyleID" = s."StyleID"
CROSS JOIN avg_score   AS a
ORDER BY musical_style;