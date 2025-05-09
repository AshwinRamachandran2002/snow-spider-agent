SELECT
    cat."name" AS "top_category"
FROM "rental"        AS r
JOIN "inventory"     AS i  ON r."inventory_id" = i."inventory_id"
JOIN "film_category" AS fc ON i."film_id"      = fc."film_id"
JOIN "category"      AS cat ON fc."category_id" = cat."category_id"
JOIN "customer"      AS cu ON r."customer_id"  = cu."customer_id"
JOIN "address"       AS ad ON cu."address_id"  = ad."address_id"
JOIN "city"          AS ci ON ad."city_id"     = ci."city_id"
WHERE (ci."city" LIKE 'A%' OR ci."city" LIKE '%-%')
  AND r."return_date" IS NOT NULL
GROUP BY cat."name"
ORDER BY SUM((julianday(r."return_date") - julianday(r."rental_date")) * 24) DESC
LIMIT 1;