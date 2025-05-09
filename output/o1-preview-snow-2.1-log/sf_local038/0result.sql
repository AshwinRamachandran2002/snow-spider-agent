SELECT a."first_name" || ' ' || a."last_name" AS "Name"
FROM PAGILA.PAGILA.ACTOR a
JOIN PAGILA.PAGILA.FILM_ACTOR fa ON a."actor_id" = fa."actor_id"
JOIN PAGILA.PAGILA.FILM f ON fa."film_id" = f."film_id"
JOIN PAGILA.PAGILA.LANGUAGE l ON f."language_id" = l."language_id"
JOIN PAGILA.PAGILA.FILM_CATEGORY fc ON f."film_id" = fc."film_id"
JOIN PAGILA.PAGILA.CATEGORY c ON fc."category_id" = c."category_id"
WHERE l."name" = 'English'
  AND f."rating" IN ('G', 'PG')
  AND c."name" = 'Children'
  AND f."length" <= 120
  AND CAST(f."release_year" AS INT) BETWEEN 2000 AND 2010
GROUP BY a."first_name", a."last_name"
ORDER BY COUNT(DISTINCT f."film_id") DESC NULLS LAST
LIMIT 1;