/* 1)  Attach each collision to its calendar year.
   2)  Within every year rank all “causes” (pcf_violation_category) by frequency.
   3)  Keep the two most frequent causes for every year, preserve their order by count.
   4)  Concatenate the two causes so every year has a single “TOP-2 pattern”.
   5)  Find the pattern that occurs in the greatest number of years (the “regular” pattern).
   6)  Return the years whose TOP-2 pattern is NOT that regular pattern. */
WITH yearly_causes AS (
    SELECT
        ci."db_year",
        c."pcf_violation_category"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"  c
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"   ci
          ON c."case_id" = ci."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
      AND c."pcf_violation_category" <> ''
),
ranked AS (
    SELECT
        "db_year",
        "pcf_violation_category",
        COUNT(*)                                           AS cnt,
        ROW_NUMBER() OVER (PARTITION BY "db_year"
                           ORDER BY COUNT(*) DESC)        AS rn
    FROM yearly_causes
    GROUP BY "db_year", "pcf_violation_category"
),
top2 AS (
    SELECT
        "db_year",
        "pcf_violation_category",
        cnt
    FROM ranked
    WHERE rn <= 2
),
year_pattern AS (
    SELECT
        "db_year",
        LISTAGG("pcf_violation_category", ' | ')
            WITHIN GROUP (ORDER BY cnt DESC)              AS top2_pattern
    FROM top2
    GROUP BY "db_year"
),
most_common_pattern AS (
    SELECT
        top2_pattern
    FROM year_pattern
    GROUP BY top2_pattern
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
SELECT
    yp."db_year"
FROM year_pattern           yp
CROSS JOIN most_common_pattern mcp
WHERE yp.top2_pattern <> mcp.top2_pattern
ORDER BY yp."db_year";