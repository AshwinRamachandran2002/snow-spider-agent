WITH start_years AS (
    SELECT DISTINCT CAST("year" AS INTEGER) AS start_year
    FROM "Movie"
    WHERE "year" IS NOT NULL
),
window_counts AS (
    SELECT s.start_year,
           COUNT(m."MID") AS total_films
    FROM   start_years AS s
    JOIN   "Movie"      AS m
      ON   CAST(m."year" AS INTEGER) BETWEEN s.start_year AND s.start_year + 9
    GROUP  BY s.start_year
)
SELECT start_year, total_films
FROM   window_counts
ORDER  BY total_films DESC, start_year
LIMIT 1;