WITH Years AS (
    SELECT DISTINCT CAST(year AS INTEGER) AS start_year
    FROM Movie
),
WindowCounts AS (
    SELECT
        y.start_year,
        COUNT(*) AS films_in_window
    FROM Years y
    JOIN Movie m
      ON CAST(m.year AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
    GROUP BY y.start_year
)
SELECT
    start_year,
    films_in_window
FROM WindowCounts
ORDER BY films_in_window DESC, start_year
LIMIT 1;