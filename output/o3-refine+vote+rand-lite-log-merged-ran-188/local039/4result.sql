WITH rental_hours AS (
    SELECT
        fc.category_id,
        (strftime('%s', r."return_date") - strftime('%s', r."rental_date")) / 3600.0 AS hours
    FROM "rental"        r
    JOIN "inventory"     i  ON i.inventory_id = r.inventory_id
    JOIN "film"          f  ON f.film_id      = i.film_id
    JOIN "film_category" fc ON fc.film_id     = f.film_id
    JOIN "customer"      cu ON cu.customer_id = r.customer_id
    JOIN "address"       ad ON ad.address_id  = cu.address_id
    JOIN "city"          ci ON ci.city_id     = ad.city_id
    WHERE r."return_date" IS NOT NULL
      AND (ci.city LIKE 'A%' OR ci.city LIKE '%-%')
),
category_totals AS (
    SELECT
        category_id,
        SUM(hours) AS total_hours
    FROM rental_hours
    GROUP BY category_id
)
SELECT c.name AS category_name
FROM category_totals ct
JOIN "category" c ON c.category_id = ct.category_id
ORDER BY ct.total_hours DESC, c.name
LIMIT 1;