WITH qualifying_films AS (
  SELECT DISTINCT f."film_id"
  FROM "PAGILA"."PAGILA"."FILM" f
  JOIN "PAGILA"."PAGILA"."FILM_CATEGORY" fc ON f."film_id" = fc."film_id"
  JOIN "PAGILA"."PAGILA"."CATEGORY" c ON fc."category_id" = c."category_id"
  WHERE
    f."language_id" = (SELECT "language_id" FROM "PAGILA"."PAGILA"."LANGUAGE" WHERE "name" = 'English')
    AND f."rating" IN ('G','PG')
    AND f."length" <= 120
    AND TO_NUMBER(f."release_year") >= 2000 AND TO_NUMBER(f."release_year") <= 2010
    AND c."name" = 'Children'
),
actor_film_counts AS (
  SELECT fa."actor_id", COUNT(*) AS film_count
  FROM qualifying_films qf
  JOIN "PAGILA"."PAGILA"."FILM_ACTOR" fa ON qf."film_id" = fa."film_id"
  GROUP BY fa."actor_id"
)
SELECT a."first_name" || ' ' || a."last_name" AS "Name"
FROM actor_film_counts afc
JOIN "PAGILA"."PAGILA"."ACTOR" a ON afc."actor_id" = a."actor_id"
WHERE afc.film_count = (
  SELECT MAX(film_count) FROM actor_film_counts
)