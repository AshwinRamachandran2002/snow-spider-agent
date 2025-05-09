SELECT 
  CONCAT(A."first_name", ' ', A."last_name") AS "Name"
FROM 
  PAGILA.PAGILA.ACTOR A
JOIN
  PAGILA.PAGILA.FILM_ACTOR FA ON A."actor_id" = FA."actor_id"
JOIN
  PAGILA.PAGILA.FILM F ON FA."film_id" = F."film_id"
JOIN
  PAGILA.PAGILA.FILM_CATEGORY FC ON F."film_id" = FC."film_id"
WHERE
  F."language_id" = 1  -- English language_id is 1
  AND F."rating" IN ('G', 'PG')
  AND F."length" <= 120
  AND F."release_year" BETWEEN '2000' AND '2010'
  AND FC."category_id" = 3  -- 'Children' category_id is 3
GROUP BY
  A."actor_id", A."first_name", A."last_name"
ORDER BY
  COUNT(*) DESC NULLS LAST
LIMIT 1;