SELECT
    D."name_id"                           AS "director_id",
    N."name"                              AS "director_name",
    COUNT(DISTINCT D."movie_id")          AS "movie_count",
    ROUND(AVG(M."duration"))              AS "avg_movie_duration",
    ROUND(AVG(R."avg_rating"), 2)         AS "avg_rating",
    SUM(R."total_votes")                  AS "total_votes",
    MIN(R."avg_rating")                   AS "min_rating",
    MAX(R."avg_rating")                   AS "max_rating",
    SUM(M."duration")                     AS "total_movie_duration"
FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING       D
JOIN IMDB_MOVIES.IMDB_MOVIES.MOVIES                  M  ON D."movie_id" = M."id"
LEFT JOIN IMDB_MOVIES.IMDB_MOVIES.RATINGS            R  ON D."movie_id" = R."movie_id"
LEFT JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES              N  ON D."name_id"  = N."id"
GROUP BY
    D."name_id",
    N."name"
ORDER BY
    "movie_count"          DESC NULLS LAST,
    "total_movie_duration" DESC NULLS LAST
LIMIT 9;