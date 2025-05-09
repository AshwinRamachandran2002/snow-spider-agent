SELECT
    dm."name_id"                         AS "director_id",
    n."name",
    COUNT(DISTINCT dm."movie_id")        AS "movie_cnt",
    ROUND(AVG(m."duration"))             AS "avg_duration",
    ROUND(AVG(r."avg_rating"), 2)        AS "avg_rating",
    SUM(r."total_votes")                 AS "total_votes",
    MIN(r."avg_rating")                  AS "min_rating",
    MAX(r."avg_rating")                  AS "max_rating",
    SUM(m."duration")                    AS "total_duration"
FROM   "director_mapping" dm
JOIN   "movies"            m  ON m."id"       = dm."movie_id"
JOIN   "ratings"           r  ON r."movie_id" = dm."movie_id"
JOIN   "names"             n  ON n."id"       = dm."name_id"
GROUP  BY dm."name_id"
ORDER  BY "movie_cnt" DESC,
          "total_duration" DESC
LIMIT 9;