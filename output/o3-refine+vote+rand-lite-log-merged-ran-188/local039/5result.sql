SELECT
    c.name AS category_name,
    SUM((julianday(COALESCE(r."return_date", 'now')) - julianday(r."rental_date")) * 24) AS total_rental_hours
FROM "rental"        AS r
JOIN "inventory"     AS i  ON r."inventory_id" = i."inventory_id"
JOIN "film_category" AS fc ON i."film_id"      = fc."film_id"
JOIN "category"      AS c  ON fc."category_id" = c."category_id"
JOIN "customer"      AS cu ON r."customer_id"  = cu."customer_id"
JOIN "address"       AS a  ON cu."address_id"  = a."address_id"
JOIN "city"          AS ci ON a."city_id"      = ci."city_id"
WHERE ci."city" LIKE 'A%' OR ci."city" LIKE '%-%'
GROUP BY c."category_id"
ORDER BY total_rental_hours DESC, c."name"
LIMIT 1;