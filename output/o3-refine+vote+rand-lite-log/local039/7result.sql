SELECT
    c.name AS category_name,
    SUM( (strftime('%s', r.return_date) - strftime('%s', r.rental_date)) / 3600.0 ) AS total_rental_hours
FROM rental            r
JOIN customer          cu ON cu.customer_id  = r.customer_id
JOIN address           ad ON ad.address_id   = cu.address_id
JOIN city              ci ON ci.city_id      = ad.city_id
JOIN inventory         i  ON i.inventory_id  = r.inventory_id
JOIN film              f  ON f.film_id       = i.film_id
JOIN film_category     fc ON fc.film_id      = f.film_id
JOIN category          c  ON c.category_id   = fc.category_id
WHERE r.return_date IS NOT NULL
  AND (ci.city LIKE 'A%' OR ci.city LIKE '%-%')
GROUP BY c.category_id, c.name
ORDER BY total_rental_hours DESC, c.name
LIMIT 1;