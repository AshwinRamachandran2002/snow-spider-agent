WITH film_revenue AS (
    SELECT f."film_id", f."title", SUM(p."amount") AS "total_revenue"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r ON p."rental_id" = r."rental_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" i ON r."inventory_id" = i."inventory_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM" f ON i."film_id" = f."film_id"
    GROUP BY f."film_id", f."title"
),
film_actor_count AS (
    SELECT fa."film_id", COUNT(DISTINCT fa."actor_id") AS "actor_count"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR" fa
    GROUP BY fa."film_id"
),
film_average_revenue AS (
    SELECT 
        fr."film_id", 
        fr."title", 
        fr."total_revenue", 
        fac."actor_count",
        ROUND(fr."total_revenue" / fac."actor_count", 4) AS "average_revenue_per_actor"
    FROM film_revenue fr
    JOIN film_actor_count fac ON fr."film_id" = fac."film_id"
),
actor_films AS (
    SELECT 
        a."actor_id", 
        a."first_name" || ' ' || a."last_name" AS "actor_name", 
        fa."film_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."ACTOR" a
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR" fa ON a."actor_id" = fa."actor_id"
),
actor_film_revenue AS (
    SELECT 
        af."actor_id", 
        af."actor_name", 
        fr."title" AS "film_title", 
        fr."average_revenue_per_actor"
    FROM actor_films af
    JOIN film_average_revenue fr ON af."film_id" = fr."film_id"
)
SELECT "actor_id", "actor_name", "film_title", "average_revenue_per_actor"
FROM (
    SELECT afr.*,
        ROW_NUMBER() OVER (
            PARTITION BY afr."actor_id" 
            ORDER BY afr."average_revenue_per_actor" DESC NULLS LAST
        ) AS rn
    FROM actor_film_revenue afr
)
WHERE rn <= 3
ORDER BY "actor_id", "average_revenue_per_actor" DESC NULLS LAST;