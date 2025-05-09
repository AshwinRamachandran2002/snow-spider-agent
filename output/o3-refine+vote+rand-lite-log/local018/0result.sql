WITH collisions_labeled AS (        -- keep only 2011 & 2021 crashes with a non‑blank category
    SELECT ci.db_year,
           TRIM(c.pcf_violation_category) AS cat
    FROM collisions  AS c
    JOIN case_ids    AS ci
      ON ci.case_id = c.case_id
    WHERE ci.db_year IN (2011, 2021)
      AND c.pcf_violation_category IS NOT NULL
      AND TRIM(c.pcf_violation_category) <> ''
),
cat_counts AS (                     -- number of crashes per category per year
    SELECT db_year,
           cat,
           COUNT(*) AS cnt
    FROM collisions_labeled
    GROUP BY db_year, cat
),
top_2021 AS (                       -- most common category in 2021
    SELECT cat
    FROM cat_counts
    WHERE db_year = 2021
    ORDER BY cnt DESC
    LIMIT 1
),
year_totals AS (                    -- total crashes per year
    SELECT db_year,
           SUM(cnt) AS total_cnt
    FROM cat_counts
    GROUP BY db_year
),
shares AS (                         -- share (%) of that category in each year
    SELECT y.db_year,
           (y.cnt * 100.0) / t.total_cnt AS share_pct
    FROM cat_counts AS y
    JOIN year_totals AS t
      ON t.db_year = y.db_year
    WHERE y.cat = (SELECT cat FROM top_2021)
),
percentages AS (                    -- ensure both years exist, default 0 if missing
    SELECT
        COALESCE(MAX(CASE WHEN db_year = 2011 THEN share_pct END), 0) AS pct_2011,
        COALESCE(MAX(CASE WHEN db_year = 2021 THEN share_pct END), 0) AS pct_2021
    FROM shares
)
SELECT ROUND(pct_2011 - pct_2021, 4) AS percentage_point_decrease
FROM percentages;