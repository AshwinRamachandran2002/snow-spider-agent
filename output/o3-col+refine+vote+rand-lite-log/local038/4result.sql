SELECT
    a."first_name" || ' ' || a."last_name" AS "full_name"
FROM "actor"        AS a
JOIN "film_actor"   AS fa ON fa."actor_id" = a."actor_id"
JOIN "film"         AS f  ON f."film_id" = fa."film_id"
JOIN "film_category" AS fc ON fc."film_id" = f."film_id"
WHERE f."language_id" = 1              -- English
  AND fc."category_id" = 3             -- Children
  AND f."rating" IN ('G','PG')
  AND f."length" <= 120
  AND f."release_year" BETWEEN '2000' AND '2010'
GROUP BY a."actor_id"
ORDER BY COUNT(*) DESC
LIMIT 1;