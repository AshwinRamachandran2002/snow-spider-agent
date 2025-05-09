SELECT  a.first_name || ' ' || a.last_name AS full_name
FROM    actor         AS a
JOIN    film_actor    AS fa ON a.actor_id = fa.actor_id
JOIN    film          AS f  ON fa.film_id = f.film_id
JOIN    film_category AS fc ON f.film_id = fc.film_id
WHERE   fc.category_id = (SELECT category_id  FROM category WHERE name = 'Children' LIMIT 1)
  AND   f.language_id  = (SELECT language_id FROM language  WHERE name = 'English'  LIMIT 1)
  AND   f.rating IN ('G','PG')
  AND   f.length <= 120
  AND   CAST(f.release_year AS INTEGER) BETWEEN 2000 AND 2010
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC
LIMIT 1;