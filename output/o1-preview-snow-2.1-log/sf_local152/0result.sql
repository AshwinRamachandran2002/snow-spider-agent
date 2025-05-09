SELECT
    dm."name_id" AS "director_id",
    n."name",
    COUNT(dm."movie_id") AS "number_of_movies",
    ROUND( (MAX(m."year") - MIN(m."year")) / NULLIF(COUNT(dm."movie_id") - 1, 0) ) AS "average_inter_movie_duration",
    ROUND(AVG(r."avg_rating"), 4) AS "average_rating",
    SUM(r."total_votes") AS "total_votes",
    MIN(r."avg_rating") AS "minimum_rating",
    MAX(r."avg_rating") AS "maximum_rating",
    SUM(m."duration") AS "total_movie_duration"
FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING dm
JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n ON dm."name_id" = n."id"
JOIN IMDB_MOVIES.IMDB_MOVIES.MOVIES m ON dm."movie_id" = m."id"
JOIN IMDB_MOVIES.IMDB_MOVIES.RATINGS r ON dm."movie_id" = r."movie_id"
WHERE m."year" IS NOT NULL
GROUP BY dm."name_id", n."name"
ORDER BY "number_of_movies" DESC NULLS LAST, "total_movie_duration" DESC NULLS LAST
LIMIT 9;