WITH target_cities AS (
    SELECT city_id
    FROM city
    WHERE city LIKE 'A%'                    -- starts with A
       OR city LIKE '%-%'                   -- contains a hyphen
),
rental_hours AS (
    SELECT r.rental_id,
           ((julianday(r.return_date) - julianday(r.rental_date)) * 24.0) AS hours
    FROM rental r
    WHERE r.return_date IS NOT NULL         -- ignore ongoing rentals
),
category_hours AS (
    SELECT cat.name,
           SUM(rh.hours) AS total_hours
    FROM rental_hours      rh
    JOIN rental            r   ON r.rental_id = rh.rental_id
    JOIN customer          cu  ON cu.customer_id = r.customer_id
    JOIN address           ad  ON ad.address_id = cu.address_id
    JOIN target_cities     tc  ON tc.city_id = ad.city_id
    JOIN inventory         i   ON i.inventory_id = r.inventory_id
    JOIN film_category     fc  ON fc.film_id = i.film_id
    JOIN category          cat ON cat.category_id = fc.category_id
    GROUP BY cat.name
)
SELECT name
FROM category_hours
ORDER BY total_hours DESC, name
LIMIT 1;