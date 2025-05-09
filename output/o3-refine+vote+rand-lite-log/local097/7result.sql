WITH years AS (
    SELECT DISTINCT CAST(year AS INTEGER) AS start_year
    FROM Movie
    WHERE year IS NOT NULL
),
counts AS (
    SELECT 
        y.start_year,
        (
            SELECT COUNT(*)
            FROM Movie m
            WHERE CAST(m.year AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
        ) AS film_count
    FROM years y
)
SELECT 
    start_year,
    film_count
FROM counts
ORDER BY film_count DESC, start_year ASC
LIMIT 1;