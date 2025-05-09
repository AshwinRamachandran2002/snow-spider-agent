SELECT
    dm."name_id"                                    AS "director_id",
    n."name"                                        AS "director_name",
    COUNT(DISTINCT dm."movie_id")                   AS "movie_count",
    ROUND(AVG(m."duration"), 0)                     AS "avg_movie_duration",
    ROUND(AVG(r."avg_rating"), 2)                   AS "avg_rating",
    SUM(COALESCE(r."total_votes", 0))               AS "total_votes",
    MIN(r."avg_rating")                             AS "min_rating",
    MAX(r."avg_rating")                             AS "max_rating",
    SUM(m."duration")                               AS "total_movie_duration"
FROM  "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" dm
JOIN  "IMDB_MOVIES"."IMDB_MOVIES"."MOVIES"          m  ON m."id"       = dm."movie_id"
LEFT JOIN "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS"     r  ON r."movie_id" = dm."movie_id"
JOIN  "IMDB_MOVIES"."IMDB_MOVIES"."NAMES"           n  ON n."id"       = dm."name_id"
GROUP BY
    dm."name_id",
    n."name"
ORDER BY
    "movie_count"         DESC NULLS LAST,
    "total_movie_duration" DESC NULLS LAST
FETCH FIRST 9 ROWS ONLY;