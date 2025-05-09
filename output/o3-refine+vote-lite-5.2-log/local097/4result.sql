WITH years AS (
    SELECT DISTINCT CAST(year AS INTEGER) AS start_year
    FROM Movie
)
SELECT
    y.start_year,
    COUNT(*) AS total_movies
FROM years y
JOIN Movie m
  ON CAST(m.year AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
GROUP BY y.start_year
ORDER BY total_movies DESC, y.start_year ASC
LIMIT 1;