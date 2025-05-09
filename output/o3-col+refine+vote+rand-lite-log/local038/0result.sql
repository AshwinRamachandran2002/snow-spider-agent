SELECT a.first_name || ' ' || a.last_name AS full_name
FROM actor         AS a
JOIN film_actor    AS fa ON a.actor_id = fa.actor_id
JOIN film          AS f  ON fa.film_id  = f.film_id
JOIN film_category AS fc ON f.film_id   = fc.film_id
JOIN category      AS c  ON fc.category_id = c.category_id
WHERE f.language_id = (SELECT language_id
                       FROM language
                       WHERE name = 'English')
  AND f.release_year BETWEEN '2000' AND '2010'
  AND f.rating IN ('G','PG')
  AND f.length <= 120
  AND c.name = 'Children'
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC, full_name
LIMIT 1;