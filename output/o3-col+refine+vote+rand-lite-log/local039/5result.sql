SELECT
       cat."name" AS "highest_rental_hours_category"
FROM   "city"      AS c
JOIN   "address"   AS a  ON c."city_id"     = a."city_id"
JOIN   "customer"  AS cu ON a."address_id"  = cu."address_id"
JOIN   "rental"    AS r  ON cu."customer_id"= r."customer_id"
JOIN   "inventory" AS i  ON r."inventory_id"= i."inventory_id"
JOIN   "film_category" AS fc ON i."film_id" = fc."film_id"
JOIN   "category"  AS cat ON fc."category_id" = cat."category_id"
WHERE  c."city" LIKE 'A%'         -- city starts with 'A'
   OR  c."city" LIKE '%-%'        -- or contains a hyphen
GROUP  BY cat."category_id"
ORDER  BY SUM((JULIANDAY(r."return_date") - JULIANDAY(r."rental_date")) * 24) DESC
LIMIT 1;