SELECT actor.first_name || ' ' || actor.last_name AS actor_name
FROM actor
JOIN film_actor     ON film_actor.actor_id = actor.actor_id
JOIN film           ON film.film_id        = film_actor.film_id
JOIN language       ON language.language_id = film.language_id
JOIN film_category  ON film_category.film_id = film.film_id
JOIN category       ON category.category_id  = film_category.category_id
WHERE language.name = 'English'
  AND category.name = 'Children'
  AND film.rating IN ('G','PG')
  AND film.length <= 120
  AND film.release_year BETWEEN 2000 AND 2010
GROUP BY actor.actor_id, actor.first_name, actor.last_name
ORDER BY COUNT(*) DESC, actor_name ASC
LIMIT 1;