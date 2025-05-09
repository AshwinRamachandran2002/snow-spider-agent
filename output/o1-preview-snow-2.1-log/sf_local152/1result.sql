WITH director_movie_counts AS (
    SELECT
        d."name_id" AS "director_id",
        COUNT(DISTINCT m."id") AS "number_of_movies",
        SUM(m."duration") AS "total_movie_duration"
    FROM
        "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" d
    JOIN
        "IMDB_MOVIES"."IMDB_MOVIES"."MOVIES" m
        ON d."movie_id" = m."id"
    GROUP BY
        d."name_id"
),
director_ratings AS (
    SELECT
        d."name_id" AS "director_id",
        ROUND(AVG(r."avg_rating"), 4) AS "average_rating",
        SUM(r."total_votes") AS "total_votes",
        MIN(r."avg_rating") AS "minimum_rating",
        MAX(r."avg_rating") AS "maximum_rating"
    FROM
        "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" d
    JOIN
        "IMDB_MOVIES"."IMDB_MOVIES"."MOVIES" m
        ON d."movie_id" = m."id"
    LEFT JOIN
        "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" r
        ON m."id" = r."movie_id"
    GROUP BY
        d."name_id"
),
director_inter_movie_gaps AS (
    SELECT
        "director_id",
        ROUND(AVG("inter_movie_gap")) AS "average_inter_movie_duration"
    FROM (
        SELECT
            d."name_id" AS "director_id",
            m."id" AS "movie_id",
            m."date_published",
            DATEDIFF(
                'day',
                LAG(m."date_published") OVER (PARTITION BY d."name_id" ORDER BY m."date_published"),
                m."date_published"
            ) AS "inter_movie_gap"
        FROM
            "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" d
        JOIN
            "IMDB_MOVIES"."IMDB_MOVIES"."MOVIES" m
            ON d."movie_id" = m."id"
        WHERE
            m."date_published" IS NOT NULL
    ) sub
    WHERE
        "inter_movie_gap" IS NOT NULL
    GROUP BY
        "director_id"
)
SELECT
    dm."director_id",
    n."name",
    dm."number_of_movies",
    COALESCE(dig."average_inter_movie_duration", 0) AS "average_inter_movie_duration",
    dr."average_rating",
    dr."total_votes",
    dr."minimum_rating",
    dr."maximum_rating",
    dm."total_movie_duration"
FROM
    director_movie_counts dm
LEFT JOIN
    director_ratings dr
    ON dm."director_id" = dr."director_id"
LEFT JOIN
    director_inter_movie_gaps dig
    ON dm."director_id" = dig."director_id"
JOIN
    "IMDB_MOVIES"."IMDB_MOVIES"."NAMES" n
    ON dm."director_id" = n."id"
ORDER BY
    dm."number_of_movies" DESC NULLS LAST,
    dm."total_movie_duration" DESC NULLS LAST
LIMIT 9;