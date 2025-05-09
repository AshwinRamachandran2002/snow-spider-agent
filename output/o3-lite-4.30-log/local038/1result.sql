SELECT a.first_name || ' ' || a.last_name AS actor_name
FROM actor AS a
JOIN film_actor   AS fa ON fa.actor_id = a.actor_id
JOIN film         AS f  ON f.film_id = fa.film_id
JOIN language     AS l  ON l.language_id = f.language_id
JOIN film_category AS fc ON fc.film_id = f.film_id
JOIN category      AS c  ON c.category_id = fc.category_id
WHERE l.name = 'English'
  AND c.name = 'Children'
  AND f.rating IN ('G','PG')
  AND f.length <= 120
  AND CAST(f.release_year AS INTEGER) BETWEEN 2000 AND 2010
GROUP BY a.actor_id
ORDER BY COUNT(DISTINCT f.film_id) DESC, actor_name
LIMIT 1;