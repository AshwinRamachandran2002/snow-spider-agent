SELECT
    cat."name" AS "highest_rental_category"
FROM "rental"        AS r
JOIN "inventory"     AS i  ON r."inventory_id" = i."inventory_id"
JOIN "film_category" AS fc ON i."film_id"      = fc."film_id"
JOIN "category"      AS cat ON fc."category_id" = cat."category_id"
JOIN "customer"      AS cu ON r."customer_id"  = cu."customer_id"
JOIN "address"       AS a  ON cu."address_id"  = a."address_id"
JOIN "city"          AS c  ON a."city_id"      = c."city_id"
WHERE r."return_date" IS NOT NULL
  AND (c."city" LIKE 'A%' OR c."city" LIKE '%-%')
GROUP BY cat."name"
ORDER BY SUM((julianday(r."return_date") - julianday(r."rental_date")) * 24) DESC
LIMIT 1;