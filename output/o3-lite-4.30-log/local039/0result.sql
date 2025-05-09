SELECT 
    c.name AS film_category,
    ROUND(SUM((julianday(r.return_date) - julianday(r.rental_date)) * 24), 4) AS total_rental_hours
FROM rental        r
JOIN inventory     i  ON r.inventory_id  = i.inventory_id
JOIN film          f  ON i.film_id       = f.film_id
JOIN film_category fc ON f.film_id       = fc.film_id
JOIN category      c  ON fc.category_id  = c.category_id
JOIN customer      cu ON r.customer_id   = cu.customer_id
JOIN address       ad ON cu.address_id   = ad.address_id
JOIN city          ci ON ad.city_id      = ci.city_id
WHERE r.return_date IS NOT NULL
  AND (ci.city LIKE 'A%' OR ci.city LIKE '%-%')
GROUP BY c.name
ORDER BY total_rental_hours DESC, c.name
LIMIT 1;