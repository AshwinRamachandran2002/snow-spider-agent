WITH yearly_counts AS (
    SELECT ci."db_year",
           c."pcf_violation_category",
           COUNT(*) AS cnt
    FROM   "collisions" AS c
    JOIN   "case_ids"  AS ci
           ON ci."case_id" = c."case_id"
    GROUP  BY ci."db_year", c."pcf_violation_category"
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY "db_year" ORDER BY cnt DESC) AS rnk
    FROM   yearly_counts
),
top2 AS (
    SELECT "db_year",
           "pcf_violation_category"
    FROM   ranked
    WHERE  rnk <= 2
),
pairs AS (
    SELECT "db_year",
           GROUP_CONCAT("pcf_violation_category", ', ') AS "top2_pair"
    FROM   top2
    GROUP  BY "db_year"
),
majority_pair AS (
    SELECT "top2_pair" AS mp
    FROM   pairs
    GROUP  BY "top2_pair"
    ORDER  BY COUNT(*) DESC
    LIMIT 1
)
SELECT p."db_year"
FROM   pairs AS p, majority_pair AS m
WHERE  p."top2_pair" <> m."mp"
ORDER  BY p."db_year";