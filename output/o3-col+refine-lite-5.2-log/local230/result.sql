WITH top_genres AS (
    SELECT g."genre"
    FROM   "genre"   AS g
    JOIN   "ratings" AS r ON r."movie_id" = g."movie_id"
    WHERE  r."avg_rating" > 8
    GROUP BY g."genre"
    ORDER  BY COUNT(*) DESC, g."genre"
    LIMIT 3
)
SELECT dm."name_id",
       n."name",
       COUNT(*) AS "movie_count"
FROM   "director_mapping" AS dm
JOIN   "ratings"          AS r ON r."movie_id" = dm."movie_id"
JOIN   "genre"            AS g ON g."movie_id" = dm."movie_id"
JOIN   "names"            AS n ON n."id"       = dm."name_id"
WHERE  r."avg_rating" > 8
  AND  g."genre" IN (SELECT "genre" FROM top_genres)
GROUP  BY dm."name_id"
ORDER  BY "movie_count" DESC, n."name"
LIMIT 4;