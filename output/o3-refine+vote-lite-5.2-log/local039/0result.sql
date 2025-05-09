WITH city_filter AS (
    SELECT city_id
    FROM city
    WHERE city LIKE 'A%'    -- starts with "A"
       OR city LIKE '%-%'   -- contains a hyphen
),
category_hours AS (
    SELECT
        fc.category_id,
        SUM((julianday(r.return_date) - julianday(r.rental_date)) * 24) AS total_hours
    FROM rental        AS r
    JOIN customer      AS cu ON r.customer_id  = cu.customer_id
    JOIN address       AS ad ON cu.address_id  = ad.address_id
    JOIN city_filter   AS cf ON ad.city_id     = cf.city_id
    JOIN inventory     AS i  ON r.inventory_id = i.inventory_id
    JOIN film_category AS fc ON i.film_id      = fc.film_id
    WHERE r.return_date IS NOT NULL            -- ignore open rentals
    GROUP BY fc.category_id
)
SELECT c.name AS category_name,
       ch.total_hours
FROM category_hours AS ch
JOIN category       AS c ON ch.category_id = c.category_id
ORDER BY ch.total_hours DESC, c.name
LIMIT 1;