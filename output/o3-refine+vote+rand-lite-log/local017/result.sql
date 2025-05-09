WITH year_cause_counts AS (          -- how often each cause (pcf_violation_category) appears per year
    SELECT
        ci.db_year  AS year,
        c.pcf_violation_category AS cause,
        COUNT(*)    AS cnt
    FROM collisions  AS c
    JOIN case_ids    AS ci  ON ci.case_id = c.case_id
    WHERE c.pcf_violation_category IS NOT NULL
    GROUP BY ci.db_year, c.pcf_violation_category
),

ranked AS (                          -- rank causes within each year by frequency
    SELECT
        year,
        cause,
        cnt,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY cnt DESC, cause) AS rn
    FROM year_cause_counts
),

top2 AS (                            -- keep the two most common causes per year
    SELECT
        year,
        GROUP_CONCAT(cause, '|') AS top_two_causes     -- build an ordered string "cause1|cause2"
    FROM (
        SELECT year, cause, rn
        FROM ranked
        WHERE rn <= 2
        ORDER BY year, rn                      -- ensures GROUP_CONCAT is in rank‑order
    )
    GROUP BY year
),

duplicate_sets AS (                  -- cause pairs that appear in more than one year
    SELECT top_two_causes
    FROM top2
    GROUP BY top_two_causes
    HAVING COUNT(*) > 1
)

SELECT year
FROM top2
WHERE top_two_causes NOT IN (SELECT top_two_causes FROM duplicate_sets)
ORDER BY year;