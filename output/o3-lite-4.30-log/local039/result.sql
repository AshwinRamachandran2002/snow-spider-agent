SELECT
    c.name AS film_category,
    ROUND(SUM((julianday(r.return_date) - julianday(r.rental_date)) * 24), 4) AS total_rental_hours
FROM rental AS r
JOIN inventory     AS i  ON r.inventory_id = i.inventory_id
JOIN film_category AS fc ON i.film_id      = fc.film_id
JOIN category      AS c  ON fc.category_id = c.category_id
JOIN customer      AS cu ON r.customer_id  = cu.customer_id
JOIN address       AS ad ON cu.address_id  = ad.address_id
JOIN city          AS ci ON ad.city_id     = ci.city_id
WHERE r.return_date IS NOT NULL
  AND (ci.city LIKE 'A%' OR ci.city LIKE '%-%')
GROUP BY c.name
ORDER BY total_rental_hours DESC
LIMIT 1;