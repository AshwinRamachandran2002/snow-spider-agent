WITH rental_hours AS (
    SELECT
        cat.name AS category_name,
        (strftime('%s', r.return_date) - strftime('%s', r.rental_date)) / 3600.0 AS hours
    FROM rental            AS r
    JOIN customer          AS cust ON cust.customer_id  = r.customer_id
    JOIN address           AS addr ON addr.address_id   = cust.address_id
    JOIN city              AS ci   ON ci.city_id        = addr.city_id
    JOIN inventory         AS inv  ON inv.inventory_id  = r.inventory_id
    JOIN film              AS f    ON f.film_id         = inv.film_id
    JOIN film_category     AS fc   ON fc.film_id        = f.film_id
    JOIN category          AS cat  ON cat.category_id   = fc.category_id
    WHERE r.return_date IS NOT NULL
      AND (ci.city LIKE 'A%' OR ci.city LIKE '%-%')
)
SELECT
    category_name,
    ROUND(SUM(hours), 4) AS total_rental_hours
FROM rental_hours
GROUP BY category_name
ORDER BY total_rental_hours DESC, category_name
LIMIT 1;