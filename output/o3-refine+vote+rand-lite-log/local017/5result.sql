WITH collisions_by_year AS (
    SELECT ci.db_year  AS year,
           c.pcf_violation_category  AS cause
    FROM collisions   AS c
    JOIN case_ids     AS ci
      ON ci.case_id = c.case_id
    WHERE c.pcf_violation_category IS NOT NULL
),
cause_counts AS (
    SELECT year,
           cause,
           COUNT(*) AS cnt
    FROM collisions_by_year
    GROUP BY year, cause
),
ranked_causes AS (
    SELECT year,
           cause,
           ROW_NUMBER() OVER (PARTITION BY year
                              ORDER BY cnt DESC, cause) AS rn
    FROM cause_counts
),
top_two AS (
    SELECT year,
           cause,
           rn
    FROM ranked_causes
    WHERE rn <= 2
),
top_pairs AS (
    /* create a deterministic “cause1|cause2” string for each year */
    SELECT year,
           GROUP_CONCAT(cause, '|') AS pair
    FROM (
        SELECT year, cause, rn
        FROM top_two
        ORDER BY year, rn          -- ensures cause1 (rn=1) precedes cause2 (rn=2)
    )
    GROUP BY year
),
pair_frequency AS (
    SELECT pair,
           COUNT(*) AS years_with_pair
    FROM top_pairs
    GROUP BY pair
),
most_common_pair AS (
    /* the pair that occurs in the largest number of years */
    SELECT pair
    FROM pair_frequency
    ORDER BY years_with_pair DESC
    LIMIT 1
)
SELECT year
FROM top_pairs
WHERE pair <> (SELECT pair FROM most_common_pair)
ORDER BY year;