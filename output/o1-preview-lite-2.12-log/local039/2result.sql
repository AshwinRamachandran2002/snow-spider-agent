SELECT "category"."name" AS "Film_category",
       ROUND(SUM((julianday("rental"."return_date") - julianday("rental"."rental_date")) * 24.0), 4) AS "Total_rental_hours"
FROM "category"
JOIN "film_category" ON "category"."category_id" = "film_category"."category_id"
JOIN "film" ON "film_category"."film_id" = "film"."film_id"
JOIN "inventory" ON "film"."film_id" = "inventory"."film_id"
JOIN "rental" ON "inventory"."inventory_id" = "rental"."inventory_id"
JOIN "customer" ON "rental"."customer_id" = "customer"."customer_id"
JOIN "address" ON "customer"."address_id" = "address"."address_id"
JOIN "city" ON "address"."city_id" = "city"."city_id"
WHERE ("city"."city" LIKE 'A%' OR "city"."city" LIKE '%-%') AND "rental"."return_date" IS NOT NULL
GROUP BY "category"."name"
ORDER BY "Total_rental_hours" DESC
LIMIT 1;