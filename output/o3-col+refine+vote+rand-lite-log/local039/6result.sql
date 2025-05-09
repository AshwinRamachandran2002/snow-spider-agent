SELECT
       cat."name" AS "top_category"
FROM   "rental"        AS r
JOIN   "inventory"      ON r."inventory_id"        = "inventory"."inventory_id"
JOIN   "film_category"  ON "inventory"."film_id"   = "film_category"."film_id"
JOIN   "category"       AS cat ON "film_category"."category_id" = cat."category_id"
JOIN   "customer"       ON r."customer_id"         = "customer"."customer_id"
JOIN   "address"        ON "customer"."address_id" = "address"."address_id"
JOIN   "city"           ON "address"."city_id"     = "city"."city_id"
WHERE  ( "city"."city" LIKE 'A%' OR "city"."city" LIKE '%-%' )
  AND  r."return_date" IS NOT NULL
GROUP BY cat."name"
ORDER BY SUM( (julianday(r."return_date") - julianday(r."rental_date")) * 24 ) DESC
LIMIT 1;