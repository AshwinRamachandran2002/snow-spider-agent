WITH years AS (
    SELECT DISTINCT CAST(year AS INTEGER) AS start_year
    FROM Movie
),
period_counts AS (
    SELECT 
        y.start_year,
        COUNT(m.MID) AS total_movies
    FROM years y
    JOIN Movie m
      ON CAST(m.year AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
    GROUP BY y.start_year
)
SELECT 
    start_year,
    total_movies
FROM period_counts
ORDER BY total_movies DESC, start_year ASC
LIMIT 1;