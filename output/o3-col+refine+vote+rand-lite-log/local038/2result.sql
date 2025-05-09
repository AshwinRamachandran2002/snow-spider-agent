SELECT a.first_name || ' ' || a.last_name AS full_name
FROM actor AS a
JOIN film_actor AS fa
  ON a.actor_id = fa.actor_id
WHERE fa.film_id IN (
    SELECT f.film_id
    FROM film AS f
    JOIN film_category AS fc ON f.film_id = fc.film_id
    WHERE f.release_year BETWEEN '2000' AND '2010'
      AND f.rating IN ('G','PG')
      AND f.length <= 120
      AND f.language_id = (SELECT language_id FROM language WHERE name = 'English')
      AND fc.category_id = (SELECT category_id FROM category WHERE name = 'Children')
)
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC
LIMIT 1;