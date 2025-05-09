WITH Years AS (
    SELECT DISTINCT CAST(year AS INTEGER) AS start_year
    FROM Movie
),
Counts AS (
    SELECT 
        y.start_year,
        (SELECT COUNT(*)
         FROM Movie m
         WHERE CAST(m.year AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
        ) AS total_count
    FROM Years y
)
SELECT start_year, total_count
FROM Counts
ORDER BY total_count DESC, start_year ASC
LIMIT 1;