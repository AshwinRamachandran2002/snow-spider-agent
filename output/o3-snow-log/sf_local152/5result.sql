WITH director_movies AS (
    SELECT
        dm."name_id"                AS director_id,
        n."name"                    AS name,
        m."id"                      AS movie_id,
        m."duration"                AS duration,
        r."avg_rating"              AS avg_rating,
        r."total_votes"             AS total_votes
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING dm
    JOIN IMDB_MOVIES.IMDB_MOVIES.MOVIES m
          ON m."id" = dm."movie_id"
    LEFT JOIN IMDB_MOVIES.IMDB_MOVIES.RATINGS r
          ON r."movie_id" = m."id"
    LEFT JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
          ON n."id" = dm."name_id"
)
SELECT
    director_id                                   AS "director_id",
    name                                          AS "director_name",
    COUNT(DISTINCT movie_id)                      AS "movie_count",
    ROUND(AVG(duration))                          AS "avg_movie_duration",
    ROUND(AVG(avg_rating), 2)                     AS "avg_rating",
    SUM(total_votes)                              AS "total_votes",
    ROUND(MIN(avg_rating), 2)                     AS "min_rating",
    ROUND(MAX(avg_rating), 2)                     AS "max_rating",
    SUM(duration)                                 AS "total_movie_duration"
FROM director_movies
GROUP BY director_id, name
ORDER BY "movie_count" DESC NULLS LAST,
         "total_movie_duration" DESC NULLS LAST
LIMIT 9;