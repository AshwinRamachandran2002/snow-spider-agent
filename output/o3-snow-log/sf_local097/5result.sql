WITH movie_years AS (
    SELECT TRY_TO_NUMBER("year") AS "yr"
    FROM DB_IMDB.DB_IMDB.MOVIE
    WHERE "year" IS NOT NULL
), distinct_years AS (
    SELECT DISTINCT "yr"
    FROM movie_years
    WHERE "yr" IS NOT NULL
), decade_counts AS (
    SELECT 
        d."yr" AS "start_year",
        (SELECT COUNT(*) 
         FROM movie_years m 
         WHERE m."yr" BETWEEN d."yr" AND d."yr" + 9) AS "total_count"
    FROM distinct_years d
)
SELECT "start_year", "total_count"
FROM decade_counts
ORDER BY "total_count" DESC NULLS LAST, "start_year" ASC
LIMIT 1;