WITH collisions_2011_2021 AS (
    SELECT ci."db_year",
           c."pcf_violation_category" AS category
    FROM "collisions" c
    JOIN "case_ids" ci ON ci."case_id" = c."case_id"
    WHERE ci."db_year" IN (2011, 2021)
      AND c."pcf_violation_category" IS NOT NULL
),
yearly_counts AS (
    SELECT "db_year",
           category,
           COUNT(*) AS cnt
    FROM collisions_2011_2021
    GROUP BY "db_year", category
),
yearly_totals AS (
    SELECT "db_year",
           SUM(cnt) AS total_cnt
    FROM yearly_counts
    GROUP BY "db_year"
),
yearly_shares AS (
    SELECT yc."db_year",
           yc.category,
           100.0 * yc.cnt / yt.total_cnt AS share
    FROM yearly_counts yc
    JOIN yearly_totals yt
      ON yt."db_year" = yc."db_year"
),
top_category_2021 AS (
    SELECT category
    FROM yearly_counts
    WHERE "db_year" = 2021
    ORDER BY cnt DESC, category
    LIMIT 1
)
SELECT ROUND(
         COALESCE(s11.share, 0) - COALESCE(s21.share, 0), 
         4
       ) AS percentage_point_decrease
FROM top_category_2021 tc
LEFT JOIN yearly_shares s21
       ON s21."db_year" = 2021 AND s21.category = tc.category
LEFT JOIN yearly_shares s11
       ON s11."db_year" = 2011 AND s11.category = tc.category;