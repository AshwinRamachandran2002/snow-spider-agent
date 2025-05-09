SELECT n."name" AS "Director Name", COUNT(*) AS "Movie Count"
FROM "ratings" r
JOIN "director_mapping" d ON r."movie_id" = d."movie_id"
JOIN "names" n ON d."name_id" = n."id"
JOIN "genre" g ON r."movie_id" = g."movie_id"
WHERE r."avg_rating" > 8 AND g."genre" IN (
  SELECT g2."genre"
  FROM "ratings" r2
  JOIN "genre" g2 ON r2."movie_id" = g2."movie_id"
  WHERE r2."avg_rating" > 8
  GROUP BY g2."genre"
  ORDER BY COUNT(*) DESC
  LIMIT 3
)
GROUP BY n."name"
ORDER BY "Movie Count" DESC
LIMIT 4;