WITH year_category_counts AS (
    -- attach every collision to its calendar year and keep only valid cause labels
    SELECT ci.db_year AS year,
           c."pcf_violation_category"       AS cause
    FROM collisions  AS c
    JOIN case_ids    AS ci ON ci.case_id = c.case_id
    WHERE c."pcf_violation_category" IS NOT NULL
),
ranked AS (
    -- for each year rank causes by how often they occur
    SELECT year,
           cause,
           COUNT(*)                                     AS cnt,
           ROW_NUMBER() OVER (
               PARTITION BY year
               ORDER BY COUNT(*) DESC, cause            -- most frequent, tie‑break alphabetically
           )                                            AS rn
    FROM year_category_counts
    GROUP BY year, cause
),
top2 AS (
    -- keep only the two most common causes per year and concatenate them (rank‑1|rank‑2)
    SELECT year,
           MAX(CASE WHEN rn = 1 THEN cause END) || '|' ||
           MAX(CASE WHEN rn = 2 THEN cause END)         AS top2_signature
    FROM ranked
    WHERE rn <= 2
    GROUP BY year
),
signature_stats AS (
    -- how many years share the same pair of dominant causes?
    SELECT year,
           top2_signature,
           COUNT(*) OVER (PARTITION BY top2_signature) AS sig_cnt
    FROM top2
)
-- years whose top‑two accident causes are different from every other year
SELECT year
FROM   signature_stats
WHERE  sig_cnt = 1;