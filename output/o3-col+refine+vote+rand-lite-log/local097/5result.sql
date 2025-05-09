WITH years AS (
    SELECT DISTINCT CAST("year" AS INTEGER) AS start_year
    FROM "Movie"
),
period_counts AS (
    SELECT y.start_year,
           (
               SELECT COUNT(*)
               FROM "Movie" m2
               WHERE CAST(m2."year" AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
           ) AS total_count
    FROM years y
)
SELECT start_year,
       total_count
FROM   period_counts
ORDER BY total_count DESC,
         start_year
LIMIT 1;