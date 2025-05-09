WITH movie_years AS (
    SELECT
        "MID",
        TO_NUMBER(REGEXP_SUBSTR("year", '\\d{4}')) AS year_num
    FROM DB_IMDB.DB_IMDB.MOVIE
    WHERE REGEXP_SUBSTR("year", '\\d{4}') IS NOT NULL
),
years AS (
    SELECT DISTINCT
        year_num AS start_year
    FROM movie_years
),
period_counts AS (
    SELECT
        y.start_year,
        COUNT(*) AS total_movies
    FROM years y
    JOIN movie_years m
      ON m.year_num BETWEEN y.start_year AND y.start_year + 9
    GROUP BY y.start_year
)
SELECT
    start_year,
    total_movies
FROM period_counts
ORDER BY total_movies DESC NULLS LAST, start_year
LIMIT 1;