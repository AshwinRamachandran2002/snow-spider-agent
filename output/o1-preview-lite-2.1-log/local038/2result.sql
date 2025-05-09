SELECT a.first_name || ' ' || a.last_name AS name
FROM actor AS a
JOIN film_actor AS fa ON a.actor_id = fa.actor_id
JOIN film AS f ON fa.film_id = f.film_id
JOIN language AS l ON f.language_id = l.language_id
JOIN film_category AS fc ON f.film_id = fc.film_id
JOIN category AS c ON fc.category_id = c.category_id
WHERE l.name = 'English'
  AND f.rating IN ('G', 'PG')
  AND f.length <= 120
  AND CAST(f.release_year AS INTEGER) BETWEEN 2000 AND 2010
  AND c.name IN ('Children', 'Family')
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC
LIMIT 1;