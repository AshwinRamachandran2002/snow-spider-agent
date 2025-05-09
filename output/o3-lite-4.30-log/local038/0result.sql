SELECT a.first_name || ' ' || a.last_name AS actor_name
FROM film AS f
JOIN language      AS l  ON f.language_id = l.language_id
JOIN film_category AS fc ON f.film_id     = fc.film_id
JOIN category      AS c  ON fc.category_id = c.category_id
JOIN film_actor    AS fa ON f.film_id     = fa.film_id
JOIN actor         AS a  ON fa.actor_id   = a.actor_id
WHERE l.name = 'English'
  AND c.name = 'Children'
  AND f.rating IN ('G','PG')
  AND f.length <= 120
  AND f.release_year BETWEEN '2000' AND '2010'
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC, a.last_name, a.first_name
LIMIT 1;