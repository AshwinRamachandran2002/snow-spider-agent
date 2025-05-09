SELECT a.first_name || ' ' || a.last_name AS full_name
FROM actor            AS a
JOIN film_actor       AS fa ON a.actor_id = fa.actor_id
JOIN film             AS f  ON f.film_id  = fa.film_id
JOIN film_category    AS fc ON fc.film_id = f.film_id
JOIN category         AS c  ON c.category_id = fc.category_id
WHERE c.name = 'Children'
  AND f.language_id = (SELECT language_id FROM language WHERE name = 'English' LIMIT 1)
  AND f.rating IN ('G','PG')
  AND CAST(f.release_year AS INTEGER) BETWEEN 2000 AND 2010
  AND f.length <= 120
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC, full_name
LIMIT 1;