SELECT actor.first_name || ' ' || actor.last_name AS name
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film ON film.film_id = film_actor.film_id
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
JOIN language ON film.language_id = language.language_id
WHERE language.name = 'English'
  AND category.name = 'Children'
  AND film.rating IN ('G', 'PG')
  AND film.length <= 120
  AND film.release_year BETWEEN '2000' AND '2010'
GROUP BY actor.actor_id
ORDER BY COUNT(*) DESC
LIMIT 1;