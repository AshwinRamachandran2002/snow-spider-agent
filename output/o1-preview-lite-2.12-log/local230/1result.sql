SELECT n."name" AS "Director Name", COUNT(*) AS "Movie Count"
FROM "names" AS n
JOIN "director_mapping" AS d ON n."id" = d."name_id"
JOIN (
    SELECT g."movie_id"
    FROM "genre" AS g
    JOIN (
        SELECT g."genre"
        FROM "genre" AS g
        JOIN "ratings" AS r ON g."movie_id" = r."movie_id"
        WHERE r."avg_rating" > 8
        GROUP BY g."genre"
        ORDER BY COUNT(*) DESC
        LIMIT 3
    ) AS top_genres ON g."genre" = top_genres."genre"
    JOIN "ratings" AS r ON g."movie_id" = r."movie_id"
    WHERE r."avg_rating" > 8
) AS top_movies ON d."movie_id" = top_movies."movie_id"
GROUP BY n."name"
ORDER BY "Movie Count" DESC
LIMIT 4;