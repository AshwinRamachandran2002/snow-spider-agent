WITH top_genres AS (
    SELECT g."genre"
    FROM "ratings" r
    JOIN "genre" g ON r."movie_id" = g."movie_id"
    WHERE r."avg_rating" > 8
    GROUP BY g."genre"
    ORDER BY COUNT(*) DESC
    LIMIT 3
)
SELECT n."name" AS "Director Name", COUNT(*) AS "Movie Count"
FROM "ratings" r
JOIN "genre" g ON r."movie_id" = g."movie_id"
JOIN "director_mapping" dm ON r."movie_id" = dm."movie_id"
JOIN "names" n ON dm."name_id" = n."id"
WHERE r."avg_rating" > 8 AND g."genre" IN (SELECT "genre" FROM top_genres)
GROUP BY n."name"
ORDER BY "Movie Count" DESC
LIMIT 4;