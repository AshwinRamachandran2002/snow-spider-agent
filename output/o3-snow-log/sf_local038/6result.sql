WITH "ENGLISH_FILMS" AS (
    SELECT f."film_id"
    FROM PAGILA.PAGILA."FILM"                     f
    JOIN PAGILA.PAGILA."LANGUAGE"                 l  ON f."language_id" = l."language_id"
    WHERE l."name"            = 'English'
      AND f."rating"          IN ('G','PG')
      AND f."length"          <= 120
      AND TRY_TO_NUMBER(f."release_year") BETWEEN 2000 AND 2010
),
"CHILDREN_FILMS" AS (
    SELECT ef."film_id"
    FROM "ENGLISH_FILMS"          ef
    JOIN PAGILA.PAGILA."FILM_CATEGORY"  fc ON ef."film_id"   = fc."film_id"
    JOIN PAGILA.PAGILA."CATEGORY"       c  ON fc."category_id" = c."category_id"
    WHERE c."name" = 'Children'
)
SELECT 
       a."first_name" || ' ' || a."last_name" AS "actor_full_name"
FROM PAGILA.PAGILA."FILM_ACTOR" fa
JOIN "CHILDREN_FILMS"           cf ON fa."film_id" = cf."film_id"
JOIN PAGILA.PAGILA."ACTOR"      a  ON fa."actor_id" = a."actor_id"
GROUP BY a."actor_id", a."first_name", a."last_name"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;