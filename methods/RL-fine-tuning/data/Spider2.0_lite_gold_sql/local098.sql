WITH actor_years AS (
   SELECT mc."PID" AS PID,
          MIN(CAST(SUBSTR(m."year", -4) AS INTEGER)) AS first_year,
          MAX(CAST(SUBSTR(m."year", -4) AS INTEGER)) AS last_year
   FROM "M_Cast" mc
   JOIN "Movie" m ON mc."MID" = m."MID"
   WHERE LENGTH(m."year") >= 4 AND SUBSTR(m."year", -4) GLOB '[0-9][0-9][0-9][0-9]'
   GROUP BY mc."PID"
),
actor_appeared_years AS (
   SELECT mc."PID", CAST(SUBSTR(m."year", -4) AS INTEGER) AS year
   FROM "M_Cast" mc
   JOIN "Movie" m ON mc."MID" = m."MID"
   WHERE LENGTH(m."year") >= 4 AND SUBSTR(m."year", -4) GLOB '[0-9][0-9][0-9][0-9]'
),
actor_all_years AS (
   SELECT PID, first_year AS year
   FROM actor_years
   UNION ALL
   SELECT ay.PID, ay.year + 1
   FROM actor_all_years ay
   JOIN actor_years a ON ay.PID = a.PID
   WHERE ay.year + 1 <= a.last_year
),
actor_missing_years AS (
   SELECT y.PID, y.year
   FROM actor_all_years y
   LEFT JOIN actor_appeared_years ay ON y.PID = ay.PID AND y.year = ay.year
   WHERE ay.PID IS NULL
),
numbered_missing_years AS (
   SELECT PID, year,
          year - ROW_NUMBER() OVER (PARTITION BY PID ORDER BY year) AS grp
   FROM actor_missing_years
),
gaps AS (
   SELECT PID, COUNT(*) AS gap_size
   FROM numbered_missing_years
   GROUP BY PID, grp
),
max_gap AS (
   SELECT PID, MAX(gap_size) AS max_gap_size
   FROM gaps
   GROUP BY PID
)
SELECT COUNT(*) AS Number_of_actors
FROM max_gap
WHERE max_gap_size < 4;