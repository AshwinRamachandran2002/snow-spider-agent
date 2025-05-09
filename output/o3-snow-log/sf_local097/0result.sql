WITH movie_years AS (
    -- Extract the first 4-digit sequence from the "year" text and convert safely to NUMBER
    SELECT 
        TRY_TO_NUMBER(REGEXP_SUBSTR("year", '\\d{4}')) AS "yr"
    FROM DB_IMDB.DB_IMDB.MOVIE
    WHERE "year" IS NOT NULL
), valid_years AS (
    -- Keep only successfully converted years
    SELECT "yr"
    FROM movie_years
    WHERE "yr" IS NOT NULL
), start_years AS (
    -- Each distinct year serves as a potential 10-year window start
    SELECT DISTINCT "yr" AS "start_year"
    FROM valid_years
)
SELECT
    sy."start_year",
    COUNT(vy."yr") AS "total_movies"
FROM start_years sy
JOIN valid_years vy
  ON vy."yr" BETWEEN sy."start_year" AND sy."start_year" + 9
GROUP BY sy."start_year"
ORDER BY "total_movies" DESC NULLS LAST, sy."start_year" ASC
LIMIT 1;