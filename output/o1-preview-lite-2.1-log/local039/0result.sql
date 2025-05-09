SELECT c."name" AS "Film_category",
       ROUND(SUM((julianday(r."return_date") - julianday(r."rental_date")) * 24), 4) AS "Total_rental_hours"
FROM "rental" r
JOIN "customer" cu ON r."customer_id" = cu."customer_id"
JOIN "address" a ON cu."address_id" = a."address_id"
JOIN "city" ci ON a."city_id" = ci."city_id"
JOIN "inventory" i ON r."inventory_id" = i."inventory_id"
JOIN "film" f ON i."film_id" = f."film_id"
JOIN "film_category" fc ON f."film_id" = fc."film_id"
JOIN "category" c ON fc."category_id" = c."category_id"
WHERE (ci."city" LIKE 'A%' OR ci."city" LIKE '%-%') AND r."return_date" IS NOT NULL
GROUP BY c."category_id", c."name"
ORDER BY "Total_rental_hours" DESC
LIMIT 1;