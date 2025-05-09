WITH director_movies AS (
    SELECT 
        dm."name_id",
        dm."movie_id",
        m."duration",
        r."avg_rating",
        r."total_votes"
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING dm
    JOIN IMDB_MOVIES.IMDB_MOVIES.MOVIES m
          ON dm."movie_id" = m."id"
    LEFT JOIN IMDB_MOVIES.IMDB_MOVIES.RATINGS r
          ON dm."movie_id" = r."movie_id"
)
SELECT
    d."name_id"                                       AS "director_id",
    n."name"                                          AS "director_name",
    COUNT(DISTINCT d."movie_id")                      AS "movie_count",
    ROUND(AVG(d."duration"), 0)                       AS "avg_inter_movie_duration",
    ROUND(AVG(d."avg_rating"), 2)                     AS "avg_rating",
    SUM(COALESCE(d."total_votes", 0))                 AS "total_votes",
    MIN(d."avg_rating")                               AS "min_rating",
    MAX(d."avg_rating")                               AS "max_rating",
    SUM(d."duration")                                 AS "total_movie_duration"
FROM director_movies d
JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
      ON d."name_id" = n."id"
GROUP BY
    d."name_id",
    n."name"
ORDER BY
    "movie_count"        DESC NULLS LAST,
    "total_movie_duration" DESC NULLS LAST
FETCH FIRST 9 ROWS ONLY;