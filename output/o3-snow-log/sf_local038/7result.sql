WITH english_language AS (
    SELECT "language_id"
    FROM PAGILA.PAGILA.LANGUAGE
    WHERE "name" = 'English'
),
qualified_films AS (
    SELECT f."film_id"
    FROM PAGILA.PAGILA.FILM               f
    JOIN english_language                 el ON f."language_id" = el."language_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY      fc ON fc."film_id"   = f."film_id"
    JOIN PAGILA.PAGILA.CATEGORY           c  ON c."category_id" = fc."category_id"
    WHERE c."name" = 'Children'
      AND f."rating" IN ('G', 'PG')
      AND f."length" <= 120
      AND TRY_TO_NUMBER(f."release_year") BETWEEN 2000 AND 2010
)
SELECT
       a."first_name" || ' ' || a."last_name" AS "actor_full_name"
FROM   PAGILA.PAGILA.ACTOR        a
JOIN   PAGILA.PAGILA.FILM_ACTOR   fa ON fa."actor_id" = a."actor_id"
JOIN   qualified_films            qf ON qf."film_id"  = fa."film_id"
GROUP  BY a."first_name", a."last_name"
ORDER  BY COUNT(DISTINCT qf."film_id") DESC NULLS LAST
LIMIT 1;