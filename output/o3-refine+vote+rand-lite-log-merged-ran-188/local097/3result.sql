WITH years AS (
    SELECT DISTINCT CAST("year" AS INTEGER) AS start_year
    FROM "Movie"
),
period_counts AS (
    SELECT 
        start_year,
        (
            SELECT COUNT(*)
            FROM "Movie" m
            WHERE CAST(m."year" AS INTEGER) BETWEEN start_year AND start_year + 9
        ) AS total_count
    FROM years
)
SELECT start_year, total_count
FROM period_counts
ORDER BY total_count DESC, start_year ASC
LIMIT 1;