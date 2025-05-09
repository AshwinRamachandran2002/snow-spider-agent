WITH total_customers AS (
  SELECT COUNT(*) AS total_cust
  FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER"
),
actor_customers AS (
  SELECT
    fa."actor_id",
    a."first_name" || ' ' || a."last_name" AS "Actor_Name",
    COUNT(DISTINCT r."customer_id") AS "customer_count"
  FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR" fa
  JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."ACTOR" a ON fa."actor_id" = a."actor_id"
  JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" i ON fa."film_id" = i."film_id"
  JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r ON i."inventory_id" = r."inventory_id"
  WHERE fa."actor_id" IN (107, 102, 198, 181, 23)
  GROUP BY fa."actor_id", a."first_name", a."last_name"
)
SELECT
  "Actor_Name",
  ROUND(("customer_count"::FLOAT / total_customers.total_cust) * 100, 4) AS "Percentage_of_Customers_Who_Rented_Films_Featuring_Actor"
FROM actor_customers, total_customers
ORDER BY "Percentage_of_Customers_Who_Rented_Films_Featuring_Actor" DESC NULLS LAST;