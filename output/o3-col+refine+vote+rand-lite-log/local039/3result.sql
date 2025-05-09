SELECT cat.name AS category_with_highest_total_rental_hours
FROM rental        AS r
JOIN inventory     AS i   ON r.inventory_id = i.inventory_id
JOIN film          AS f   ON i.film_id      = f.film_id
JOIN film_category AS fc  ON f.film_id      = fc.film_id
JOIN category      AS cat ON fc.category_id = cat.category_id
JOIN customer      AS cu  ON r.customer_id  = cu.customer_id
JOIN address       AS a   ON cu.address_id  = a.address_id
JOIN city          AS ct  ON a.city_id      = ct.city_id
WHERE (ct.city LIKE 'A%' OR ct.city LIKE '%-%')
  AND r.return_date IS NOT NULL
GROUP BY cat.name
ORDER BY SUM((julianday(r.return_date) - julianday(r.rental_date)) * 24) DESC
LIMIT 1;