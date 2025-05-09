SELECT CONCAT("A"."first_name", ' ', "A"."last_name") AS "name"
FROM "PAGILA"."PAGILA"."ACTOR" AS "A"
JOIN "PAGILA"."PAGILA"."FILM_ACTOR" AS "FA"
  ON "A"."actor_id" = "FA"."actor_id"
JOIN "PAGILA"."PAGILA"."FILM" AS "F"
  ON "FA"."film_id" = "F"."film_id"
JOIN "PAGILA"."PAGILA"."LANGUAGE" AS "L"
  ON "F"."language_id" = "L"."language_id"
JOIN "PAGILA"."PAGILA"."FILM_CATEGORY" AS "FC"
  ON "F"."film_id" = "FC"."film_id"
JOIN "PAGILA"."PAGILA"."CATEGORY" AS "C"
  ON "FC"."category_id" = "C"."category_id"
WHERE "L"."name" = 'English'
  AND "C"."name" = 'Children'
  AND "F"."rating" IN ('G', 'PG')
  AND "F"."length" <= 120
  AND "F"."release_year" BETWEEN 2000 AND 2010
GROUP BY "A"."first_name", "A"."last_name"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;