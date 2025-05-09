/*-------------------------------------------------------------
  1. style_scores : total weighted score for each musical style
  2. avg_score    : overall average of those totals
  3. Final SELECT : add style name & absolute difference
--------------------------------------------------------------*/
WITH style_scores AS (
    SELECT
        mp."StyleID",
        SUM(
            CASE mp."PreferenceSeq"
                 WHEN 1 THEN 3      -- first choice
                 WHEN 2 THEN 2      -- second choice
                 WHEN 3 THEN 1      -- third choice
                 ELSE 0             -- any other value (not counted)
            END
        ) AS total_weighted_score
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES mp
    WHERE mp."PreferenceSeq" IN (1,2,3)               -- consider only ranked choices
    GROUP BY mp."StyleID"
),    
avg_score AS (
    SELECT AVG(total_weighted_score) AS avg_total_weighted_score
    FROM style_scores
)

SELECT
    ss."StyleID",
    ms."StyleName",
    ss.total_weighted_score,
    avg_score.avg_total_weighted_score,
    ABS(ss.total_weighted_score - avg_score.avg_total_weighted_score) AS abs_difference
FROM style_scores  ss
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES ms
     ON ms."StyleID" = ss."StyleID"
CROSS JOIN avg_score
ORDER BY abs_difference DESC NULLS LAST;