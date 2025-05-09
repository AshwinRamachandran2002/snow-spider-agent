WITH top_genres AS (          -- 1) three most common genres among movies rated > 8
    SELECT g."genre"
    FROM   "ratings" AS r
    JOIN   "genre"   AS g ON r."movie_id" = g."movie_id"
    WHERE  r."avg_rating" > 8
    GROUP BY g."genre"
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
director_counts AS (          -- 2) how many >8-rated films (within those genres) each director has
    SELECT dm."name_id",
           COUNT(DISTINCT dm."movie_id") AS high_rated_movies
    FROM   "ratings"          AS r
    JOIN   "director_mapping" AS dm ON r."movie_id" = dm."movie_id"
    JOIN   "genre"            AS g  ON dm."movie_id" = g."movie_id"
    WHERE  r."avg_rating" > 8
      AND  g."genre" IN (SELECT "genre" FROM top_genres)
    GROUP BY dm."name_id"
)
SELECT n."name"                 AS director,
       dc."high_rated_movies"   -- 3) top-4 directors by that count
FROM   director_counts AS dc
JOIN   "names"        AS n ON dc."name_id" = n."id"
ORDER BY dc."high_rated_movies" DESC,
         n."name"
LIMIT 4;