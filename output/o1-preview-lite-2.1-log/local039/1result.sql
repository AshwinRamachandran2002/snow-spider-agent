SELECT
  "category"."name" AS "Film_category",
  ROUND(SUM((JulianDay("rental"."return_date") - JulianDay("rental"."rental_date")) * 24.0), 4) AS "Total_rental_hours"
FROM
  "rental"
  JOIN "inventory" ON "rental"."inventory_id" = "inventory"."inventory_id"
  JOIN "film_category" ON "inventory"."film_id" = "film_category"."film_id"
  JOIN "category" ON "film_category"."category_id" = "category"."category_id"
  JOIN "customer" ON "rental"."customer_id" = "customer"."customer_id"
  JOIN "address" ON "customer"."address_id" = "address"."address_id"
  JOIN "city" ON "address"."city_id" = "city"."city_id"
WHERE
  "rental"."return_date" IS NOT NULL
  AND ("city"."city" LIKE 'A%' OR "city"."city" LIKE '%-%')
GROUP BY
  "category"."name"
ORDER BY
  "Total_rental_hours" DESC
LIMIT 1;