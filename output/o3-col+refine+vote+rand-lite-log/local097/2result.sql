WITH years AS (
    SELECT DISTINCT CAST("year" AS INTEGER) AS start_year
    FROM "Movie"
),
span_counts AS (
    SELECT 
        y.start_year,
        (
            SELECT COUNT(*)
            FROM "Movie" m
            WHERE CAST(m."year" AS INTEGER) >= y.start_year
              AND CAST(m."year" AS INTEGER) <  y.start_year + 10
        ) AS total_films
    FROM years y
)
SELECT 
    start_year, 
    total_films
FROM span_counts
ORDER BY total_films DESC, start_year
LIMIT 1;