SELECT
    cat."name" AS category_name,
    SUM( (julianday(r."return_date") - julianday(r."rental_date")) * 24 ) AS total_hours
FROM "rental"      r
JOIN "inventory"    i   ON r."inventory_id" = i."inventory_id"
JOIN "film_category" fc ON i."film_id"      = fc."film_id"
JOIN "category"     cat ON fc."category_id" = cat."category_id"
JOIN "customer"     cu  ON r."customer_id"  = cu."customer_id"
JOIN "address"      ad  ON cu."address_id"  = ad."address_id"
JOIN "city"         ci  ON ad."city_id"     = ci."city_id"
WHERE (ci."city" LIKE 'A%' OR ci."city" LIKE '%-%')
  AND r."return_date" IS NOT NULL
GROUP BY cat."category_id", cat."name"
ORDER BY total_hours DESC, cat."name" ASC
LIMIT 1;