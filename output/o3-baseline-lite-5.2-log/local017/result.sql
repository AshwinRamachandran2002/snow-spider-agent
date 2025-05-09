WITH year_cause_counts AS (
    SELECT 
        ci.db_year                          AS year,
        COALESCE(c."pcf_violation_category",'unknown') AS cause,
        COUNT(*)                            AS cnt
    FROM collisions AS c
    JOIN case_ids  AS ci ON ci.case_id = c.case_id
    GROUP BY ci.db_year, cause
),
ranked_causes AS (
    SELECT
        year,
        cause,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY cnt DESC, cause) AS rn
    FROM year_cause_counts
),
top_two_causes AS (
    SELECT year, cause
    FROM ranked_causes
    WHERE rn <= 2
),
year_pairs AS (
    SELECT 
        year,
        GROUP_CONCAT(cause, '|' ) AS causes_pair
    FROM (
        SELECT year, cause
        FROM top_two_causes
        ORDER BY year, cause
    )
    GROUP BY year
),
pair_frequencies AS (
    SELECT causes_pair, COUNT(*) AS freq
    FROM year_pairs
    GROUP BY causes_pair
)
SELECT yp.year
FROM year_pairs AS yp
JOIN pair_frequencies AS pf ON pf.causes_pair = yp.causes_pair
WHERE pf.freq = 1
ORDER BY yp.year;