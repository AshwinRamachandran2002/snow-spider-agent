SELECT "category_name"
FROM (
    SELECT
        ca."name" AS "category_name",
        SUM( (julianday(r."return_date") - julianday(r."rental_date")) * 24 ) AS "total_hours"
    FROM "rental"        AS r
    JOIN "customer"      AS cu ON r."customer_id"  = cu."customer_id"
    JOIN "address"       AS a  ON cu."address_id"  = a."address_id"
    JOIN "city"          AS c  ON a."city_id"      = c."city_id"
    JOIN "inventory"     AS i  ON r."inventory_id" = i."inventory_id"
    JOIN "film_category" AS fc ON i."film_id"      = fc."film_id"
    JOIN "category"      AS ca ON fc."category_id" = ca."category_id"
    WHERE (c."city" LIKE 'A%' OR c."city" LIKE '%-%')
      AND r."return_date" IS NOT NULL
    GROUP BY ca."name"
    ORDER BY "total_hours" DESC
    LIMIT 1
);