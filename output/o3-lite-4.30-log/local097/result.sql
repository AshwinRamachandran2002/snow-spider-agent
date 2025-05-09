WITH years AS (
    SELECT DISTINCT CAST("year" AS INTEGER) AS start_year
    FROM Movie
    WHERE CAST("year" AS INTEGER) <> 0
),
window_counts AS (
    SELECT
        y.start_year,
        COUNT(*) AS total_films
    FROM years y
    JOIN Movie m
      ON CAST(m."year" AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
     AND CAST(m."year" AS INTEGER) <> 0
    GROUP BY y.start_year
)
SELECT start_year, total_films
FROM window_counts
ORDER BY total_films DESC, start_year
LIMIT 1;