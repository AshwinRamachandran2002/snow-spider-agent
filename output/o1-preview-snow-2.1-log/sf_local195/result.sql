WITH top_actors AS (
    SELECT "actor_id", COUNT("film_id") AS "film_count"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"
    GROUP BY "actor_id"
    ORDER BY "film_count" DESC NULLS LAST
    LIMIT 5
),
actor_customers AS (
    SELECT
        "FA"."actor_id",
        COUNT(DISTINCT "R"."customer_id") AS "customer_count"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR" AS "FA"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" AS "I" ON "FA"."film_id" = "I"."film_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" AS "R" ON "I"."inventory_id" = "R"."inventory_id"
    WHERE "FA"."actor_id" IN (SELECT "actor_id" FROM top_actors)
    GROUP BY "FA"."actor_id"
),
actor_names AS (
    SELECT "actor_id", CONCAT("first_name", ' ', "last_name") AS "Actor_Name"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."ACTOR"
    WHERE "actor_id" IN (SELECT "actor_id" FROM top_actors)
),
total_customers AS (
    SELECT COUNT(DISTINCT "customer_id") AS "total_customers"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER"
)
SELECT
    "AN"."Actor_Name",
    ROUND(("AC"."customer_count"::FLOAT / "TC"."total_customers") * 100, 4) AS "Percentage_of_Customers_Who_Rented_Films_Featuring_Actor"
FROM
    actor_customers AS "AC"
    JOIN actor_names AS "AN" ON "AC"."actor_id" = "AN"."actor_id"
    CROSS JOIN total_customers AS "TC"
ORDER BY
    "Percentage_of_Customers_Who_Rented_Films_Featuring_Actor" DESC NULLS LAST;