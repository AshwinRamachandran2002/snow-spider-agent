WITH eligible_films AS (
    SELECT f.film_id
    FROM film            AS f
    JOIN language        AS l  ON l.language_id = f.language_id
    JOIN film_category   AS fc ON fc.film_id     = f.film_id
    JOIN category        AS c  ON c.category_id  = fc.category_id
    WHERE l.name = 'English'
      AND c.name = 'Children'
      AND f.rating IN ('G','PG')
      AND f.length <= 120
      AND CAST(f.release_year AS INTEGER) BETWEEN 2000 AND 2010
)
SELECT a.first_name || ' ' || a.last_name AS actor_full_name
FROM actor       AS a
JOIN film_actor  AS fa ON fa.actor_id = a.actor_id
JOIN eligible_films ef ON ef.film_id  = fa.film_id
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC, a.actor_id
LIMIT 1;