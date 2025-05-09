WITH top_genres AS (
    SELECT g."genre"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" r
    JOIN "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" g ON r."movie_id" = g."movie_id"
    WHERE r."avg_rating" > 8
    GROUP BY g."genre"
    ORDER BY COUNT(DISTINCT r."movie_id") DESC NULLS LAST
    LIMIT 3
)
SELECT n."name" AS "Director_Name", COUNT(DISTINCT r."movie_id") AS "Movie_Count"
FROM "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" r
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" g ON r."movie_id" = g."movie_id"
JOIN top_genres tg ON g."genre" = tg."genre"
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" dm ON r."movie_id" = dm."movie_id"
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."NAMES" n ON dm."name_id" = n."id"
WHERE r."avg_rating" > 8
GROUP BY n."name"
ORDER BY COUNT(DISTINCT r."movie_id") DESC NULLS LAST, n."name"
LIMIT 4;