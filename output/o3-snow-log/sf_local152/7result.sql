WITH "DIRECTOR_MOVIES" AS (
    SELECT 
        dm."name_id"         AS "director_id",
        m."id"               AS "movie_id",
        m."duration"         AS "movie_duration",
        r."avg_rating",
        r."total_votes"
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING dm
    JOIN IMDB_MOVIES.IMDB_MOVIES.MOVIES           m ON dm."movie_id" = m."id"
    LEFT JOIN IMDB_MOVIES.IMDB_MOVIES.RATINGS     r ON m."id"      = r."movie_id"
),
"DIR_STATS" AS (
    SELECT
        d."director_id"                              AS "director_id",
        n."name"                                     AS "director_name",
        COUNT(DISTINCT d."movie_id")                 AS "movie_count",
        ROUND(AVG(d."movie_duration"))               AS "avg_movie_duration",
        ROUND(AVG(d."avg_rating"), 2)                AS "avg_rating",
        SUM(d."total_votes")                         AS "total_votes",
        MIN(d."avg_rating")                          AS "min_rating",
        MAX(d."avg_rating")                          AS "max_rating",
        SUM(d."movie_duration")                      AS "total_movie_duration"
    FROM "DIRECTOR_MOVIES" d
    JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
         ON d."director_id" = n."id"
    GROUP BY d."director_id", n."name"
)
SELECT 
    "director_id",
    "director_name",
    "movie_count",
    "avg_movie_duration",
    "avg_rating",
    "total_votes",
    "min_rating",
    "max_rating",
    "total_movie_duration"
FROM "DIR_STATS"
ORDER BY 
    "movie_count"          DESC NULLS LAST,
    "total_movie_duration" DESC NULLS LAST
LIMIT 9;