WITH TopGenres AS (
  SELECT g."genre"
  FROM "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" g
  JOIN "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" r ON g."movie_id" = r."movie_id"
  WHERE r."avg_rating" > 8
  GROUP BY g."genre"
  ORDER BY COUNT(*) DESC NULLS LAST
  LIMIT 3
)
SELECT n."name" AS "Director_Name", COUNT(*) AS "Movie_Count"
FROM "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" r
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" g ON r."movie_id" = g."movie_id"
JOIN TopGenres tg ON g."genre" = tg."genre"
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" d ON r."movie_id" = d."movie_id"
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."NAMES" n ON d."name_id" = n."id"
WHERE r."avg_rating" > 8
GROUP BY n."name"
ORDER BY "Movie_Count" DESC NULLS LAST
LIMIT 4;