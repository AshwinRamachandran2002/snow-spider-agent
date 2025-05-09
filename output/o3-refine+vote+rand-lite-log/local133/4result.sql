WITH scores AS (
    -- 1.  Calculate the weighted score for every style that was ranked
    SELECT
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                 WHEN 1 THEN 3      -- first choice
                 WHEN 2 THEN 2      -- second choice
                 WHEN 3 THEN 1      -- third choice
                 ELSE 0
            END
        ) AS total_score
    FROM "Musical_Preferences"
    GROUP BY "StyleID"
),
avg_val AS (
    -- 2.  Average weighted score across all styles that were ranked
    SELECT AVG(total_score) AS avg_score
    FROM scores
)
-- 3.  Return each style’s score and its absolute difference from the average
SELECT
    s."StyleID",
    m."StyleName",
    s.total_score,
    ROUND(a.avg_score, 4)                         AS avg_total_score,
    ROUND(ABS(s.total_score - a.avg_score), 4)    AS abs_difference
FROM scores AS s
JOIN avg_val AS a               -- one‑row CTE holding the average
JOIN "Musical_Styles" AS m
  ON m."StyleID" = s."StyleID"
ORDER BY abs_difference DESC,   -- largest deviation first
         s."StyleID";