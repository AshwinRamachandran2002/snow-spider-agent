WITH collisions_year AS (
    SELECT
        c."pcf_violation_category" AS category,
        ci."db_year"               AS yr
    FROM "collisions" AS c
    JOIN "case_ids"  AS ci ON ci."case_id" = c."case_id"
    WHERE ci."db_year" IN (2011, 2021)
),
cnts AS (
    SELECT
        yr,
        category,
        COUNT(*) AS cnt
    FROM collisions_year
    GROUP BY yr, category
),
totals AS (
    SELECT
        yr,
        SUM(cnt) AS total_cnt
    FROM cnts
    GROUP BY yr
),
shares AS (
    SELECT
        c.yr,
        c.category,
        100.0 * c.cnt / t.total_cnt AS share
    FROM cnts   AS c
    JOIN totals AS t ON t.yr = c.yr
),
top2021 AS (
    SELECT category
    FROM shares
    WHERE yr = 2021
    ORDER BY share DESC
    LIMIT 1
)
SELECT ROUND(
         (SELECT share FROM shares s JOIN top2021 t ON t.category = s.category WHERE s.yr = 2011) -
         (SELECT share FROM shares s JOIN top2021 t ON t.category = s.category WHERE s.yr = 2021),
         4
       ) AS percentage_point_decrease;