SELECT a.first_name || ' ' || a.last_name AS full_name
FROM actor AS a
JOIN (
    SELECT fa.actor_id, COUNT(*) AS appearances
    FROM film_actor        AS fa
    JOIN film              AS f  ON f.film_id  = fa.film_id
    JOIN film_category     AS fc ON fc.film_id = f.film_id
    WHERE fc.category_id = (SELECT category_id  FROM category WHERE name = 'Children')
      AND f.language_id   = (SELECT language_id FROM language  WHERE name = 'English')
      AND f.release_year BETWEEN '2000' AND '2010'
      AND f.rating IN ('G','PG')
      AND f.length <= 120
    GROUP BY fa.actor_id
    ORDER BY appearances DESC
    LIMIT 1
) AS top_actor
ON a.actor_id = top_actor.actor_id;