SELECT
    n."id"                              AS "director_id",
    n."name",
    COUNT(DISTINCT m."id")              AS "movie_count",
    ROUND(AVG(m."duration"))            AS "avg_movie_duration",
    ROUND(AVG(r."avg_rating"), 2)       AS "avg_rating",
    SUM(r."total_votes")                AS "total_votes",
    MIN(r."avg_rating")                 AS "min_rating",
    MAX(r."avg_rating")                 AS "max_rating",
    SUM(m."duration")                   AS "total_movie_duration"
FROM   "director_mapping" d
JOIN   "names"            n ON d."name_id" = n."id"
JOIN   "movies"           m ON d."movie_id" = m."id"
JOIN   "ratings"          r ON m."id"      = r."movie_id"
GROUP  BY n."id", n."name"
ORDER  BY "movie_count" DESC,
          "total_movie_duration" DESC
LIMIT 9;