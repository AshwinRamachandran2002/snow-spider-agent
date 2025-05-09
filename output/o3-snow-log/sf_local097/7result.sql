WITH movies AS (
    SELECT TRY_TO_NUMBER("year") AS yr
    FROM DB_IMDB.DB_IMDB.MOVIE
    WHERE "year" IS NOT NULL
      AND TRY_TO_NUMBER("year") IS NOT NULL
),
start_years AS (
    SELECT DISTINCT yr AS start_year
    FROM movies
),
period_counts AS (
    SELECT 
        s.start_year,
        COUNT(*) AS total_films
    FROM start_years s
    JOIN movies m
      ON m.yr BETWEEN s.start_year AND s.start_year + 9
    GROUP BY s.start_year
)
SELECT 
    start_year,
    total_films
FROM period_counts
ORDER BY total_films DESC NULLS LAST, start_year ASC
LIMIT 1;