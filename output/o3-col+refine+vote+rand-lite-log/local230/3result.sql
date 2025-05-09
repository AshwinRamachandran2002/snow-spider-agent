WITH top_genres AS (
    SELECT g."genre"
    FROM   "ratings" AS r
    JOIN   "genre"   AS g  ON r."movie_id" = g."movie_id"
    WHERE  r."avg_rating" > 8.0
    GROUP  BY g."genre"
    ORDER  BY COUNT(DISTINCT r."movie_id") DESC
    LIMIT 3
),
high_rated_movies AS (
    SELECT DISTINCT r."movie_id"
    FROM   "ratings" AS r
    JOIN   "genre"   AS g  ON r."movie_id" = g."movie_id"
    JOIN   top_genres tg   ON g."genre" = tg."genre"
    WHERE  r."avg_rating" > 8.0
)
SELECT n."name"                               AS director,
       COUNT(DISTINCT h."movie_id")           AS high_rated_movie_count
FROM   high_rated_movies  AS h
JOIN   "director_mapping" AS d ON h."movie_id" = d."movie_id"
JOIN   "names"            AS n ON d."name_id"  = n."id"
GROUP  BY n."name"
ORDER  BY high_rated_movie_count DESC,
          n."name"
LIMIT 4;