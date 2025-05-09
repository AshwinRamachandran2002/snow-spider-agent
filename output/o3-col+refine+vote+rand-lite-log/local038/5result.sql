SELECT
       a.first_name || ' ' || a.last_name AS full_name
FROM   actor          AS a
JOIN   film_actor     AS fa ON a.actor_id = fa.actor_id
JOIN   film           AS f  ON f.film_id  = fa.film_id
JOIN   film_category  AS fc ON f.film_id  = fc.film_id
JOIN   category       AS c  ON c.category_id = fc.category_id
WHERE  c.name = 'Children'
  AND  f.language_id = 1                -- English
  AND  f.rating IN ('G','PG')
  AND  f.length <= 120
  AND  CAST(f.release_year AS INTEGER) BETWEEN 2000 AND 2010
GROUP BY a.actor_id
ORDER BY COUNT(*) DESC
LIMIT 1;