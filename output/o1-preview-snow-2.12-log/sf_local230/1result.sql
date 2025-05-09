WITH TopGenres AS (
  SELECT G."genre"
  FROM "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" AS R
  JOIN "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" AS G ON R."movie_id" = G."movie_id"
  WHERE R."avg_rating" > 8
  GROUP BY G."genre"
  ORDER BY COUNT(*) DESC NULLS LAST
  LIMIT 3
)
SELECT N."name" AS "Director_Name", COUNT(DISTINCT R."movie_id") AS "Movie_Count"
FROM "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS" AS R
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" AS G ON R."movie_id" = G."movie_id"
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" AS DM ON R."movie_id" = DM."movie_id"
JOIN "IMDB_MOVIES"."IMDB_MOVIES"."NAMES" AS N ON DM."name_id" = N."id"
WHERE R."avg_rating" > 8
  AND G."genre" IN (SELECT "genre" FROM TopGenres)
GROUP BY N."name"
ORDER BY "Movie_Count" DESC NULLS LAST, N."name" ASC
LIMIT 4;