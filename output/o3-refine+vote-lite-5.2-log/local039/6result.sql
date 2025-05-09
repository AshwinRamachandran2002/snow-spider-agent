SELECT
    cat.name AS category,
    SUM((JULIANDAY(r.return_date) - JULIANDAY(r.rental_date)) * 24) AS total_rental_hours
FROM rental r
JOIN customer cu      ON r.customer_id = cu.customer_id
JOIN address  ad      ON cu.address_id = ad.address_id
JOIN city     ci      ON ad.city_id   = ci.city_id
JOIN inventory i      ON r.inventory_id = i.inventory_id
JOIN film      f      ON i.film_id      = f.film_id
JOIN film_category fc ON f.film_id      = fc.film_id
JOIN category  cat    ON fc.category_id = cat.category_id
WHERE (ci.city LIKE 'A%' OR ci.city LIKE '%-%')
  AND r.return_date IS NOT NULL
GROUP BY cat.category_id, cat.name
ORDER BY total_rental_hours DESC, cat.name
LIMIT 1;