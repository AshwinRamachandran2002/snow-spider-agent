SELECT
    ca."name" AS "category_with_highest_rental_hours"
FROM "rental"        AS re
JOIN "customer"      AS cu  ON re."customer_id"   = cu."customer_id"
JOIN "address"       AS ad  ON cu."address_id"    = ad."address_id"
JOIN "city"          AS ci  ON ad."city_id"       = ci."city_id"
JOIN "inventory"     AS inv ON re."inventory_id"  = inv."inventory_id"
JOIN "film_category" AS fc  ON inv."film_id"      = fc."film_id"
JOIN "category"      AS ca  ON fc."category_id"   = ca."category_id"
WHERE (ci."city" LIKE 'A%' OR ci."city" LIKE '%-%')
  AND re."return_date" IS NOT NULL
GROUP BY ca."name"
ORDER BY SUM((julianday(re."return_date") - julianday(re."rental_date")) * 24) DESC
LIMIT 1;