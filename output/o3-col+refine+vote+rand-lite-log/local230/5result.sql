WITH top_genres AS (
    SELECT g."genre"
    FROM "genre" AS g
    JOIN "ratings" AS r ON g."movie_id" = r."movie_id"
    WHERE r."avg_rating" > 8
    GROUP BY g."genre"
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
top_directors AS (
    SELECT dm."name_id",
           COUNT(DISTINCT dm."movie_id") AS movie_count
    FROM "director_mapping" AS dm
    JOIN "ratings" AS r ON dm."movie_id" = r."movie_id"
    JOIN "genre"  AS g ON dm."movie_id" = g."movie_id"
    WHERE r."avg_rating" > 8
      AND g."genre" IN (SELECT "genre" FROM top_genres)
    GROUP BY dm."name_id"
    ORDER BY movie_count DESC
    LIMIT 4
)
SELECT n."name"       AS director,
       td.movie_count AS movies_above_8_in_top_genres
FROM   top_directors AS td
JOIN   "names"       AS n ON n."id" = td."name_id"
ORDER  BY td.movie_count DESC;