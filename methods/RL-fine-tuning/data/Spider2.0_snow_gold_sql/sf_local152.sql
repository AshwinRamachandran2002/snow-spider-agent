WITH director_movies AS (
    SELECT dm."name_id" AS "director_id",
           m."id" AS "movie_id",
           m."title",
           m."year",
           m."duration",
           r."avg_rating",
           r."total_votes"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" dm
    JOIN "IMDB_MOVIES"."IMDB_MOVIES"."MOVIES" m
      ON dm."movie_id" = m."id"
    LEFT JOIN "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" r
      ON m."id" = r."movie_id"
),
director_stats AS (
    SELECT 
        dm."name_id" AS "director_id",
        COUNT(*) AS "number_of_movies",
        COALESCE(SUM(m."duration"), 0) AS "total_movie_duration",
        ROUND(AVG(r."avg_rating"), 4) AS "average_rating",
        COALESCE(SUM(r."total_votes"), 0) AS "total_votes",
        ROUND(MIN(r."avg_rating"), 4) AS "minimum_rating",
        ROUND(MAX(r."avg_rating"), 4) AS "maximum_rating"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" dm
    JOIN "IMDB_MOVIES"."IMDB_MOVIES"."MOVIES" m
      ON dm."movie_id" = m."id"
    LEFT JOIN "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" r
      ON m."id" = r."movie_id"
    GROUP BY dm."name_id"
),
inter_movie_durations AS (
    SELECT
        "director_id",
        ROUND(AVG("year_difference")) AS "average_inter_movie_duration"
    FROM (
        SELECT
            "director_id",
            "year",
            "year" - LAG("year") OVER (PARTITION BY "director_id" ORDER BY "year") AS "year_difference"
        FROM director_movies
    ) sub
    WHERE "year_difference" IS NOT NULL
    GROUP BY "director_id"
),
directors AS (
    SELECT "id" AS "director_id", "name"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."NAMES"
)
SELECT 
    ds."director_id",
    d."name",
    ds."number_of_movies",
    COALESCE(imd."average_inter_movie_duration", 0) AS "average_inter_movie_duration",
    ds."average_rating",
    ds."total_votes",
    ds."minimum_rating",
    ds."maximum_rating",
    ds."total_movie_duration"
FROM director_stats ds
LEFT JOIN inter_movie_durations imd ON ds."director_id" = imd."director_id"
LEFT JOIN directors d ON ds."director_id" = d."director_id"
ORDER BY ds."number_of_movies" DESC NULLS LAST, ds."total_movie_duration" DESC NULLS LAST
LIMIT 9;