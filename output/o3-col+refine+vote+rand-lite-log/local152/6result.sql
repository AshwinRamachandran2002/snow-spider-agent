WITH director_movies AS (
    SELECT dm."name_id",
           n."name",
           m."id"            AS "movie_id",
           m."year",
           m."duration",
           r."avg_rating",
           r."total_votes"
    FROM "director_mapping" AS dm
    JOIN "names"            AS n ON n."id" = dm."name_id"
    JOIN "movies"           AS m ON m."id" = dm."movie_id"
    LEFT JOIN "ratings"     AS r ON r."movie_id" = m."id"
),
gaps AS (
    SELECT *,
           LAG("year") OVER (PARTITION BY "name_id" ORDER BY "year") AS "prev_year"
    FROM director_movies
),
aggregated AS (
    SELECT
        "name_id",
        "name",
        COUNT(DISTINCT "movie_id")                                                AS "movie_count",
        ROUND(AVG(CASE WHEN "prev_year" IS NOT NULL THEN "year" - "prev_year" END)) AS "avg_inter_movie_duration",
        ROUND(AVG("avg_rating"), 2)                                               AS "avg_rating",
        SUM("total_votes")                                                        AS "total_votes",
        MIN("avg_rating")                                                         AS "min_rating",
        MAX("avg_rating")                                                         AS "max_rating",
        SUM("duration")                                                           AS "total_movie_duration"
    FROM gaps
    GROUP BY "name_id", "name"
)
SELECT *
FROM aggregated
ORDER BY "movie_count" DESC,
         "total_movie_duration" DESC
LIMIT 9;