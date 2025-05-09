SELECT a."first_name" || ' ' || a."last_name" AS "actor_full_name"
FROM "actor" AS a
JOIN (
    SELECT fa."actor_id",
           COUNT(*) AS "appearances"
    FROM "film_actor"     AS fa
    JOIN "film"           AS f  ON fa."film_id" = f."film_id"
    JOIN "film_category"  AS fc ON f."film_id" = fc."film_id"
    WHERE fc."category_id" = 3            -- Children category
      AND f."language_id"  = 1            -- English
      AND f."rating"      IN ('G','PG')   -- Rating filter
      AND f."length"       <= 120         -- Running time filter
      AND f."release_year" BETWEEN '2000' AND '2010'
    GROUP BY fa."actor_id"
    ORDER BY "appearances" DESC
    LIMIT 1
) AS top_actor
ON a."actor_id" = top_actor."actor_id";