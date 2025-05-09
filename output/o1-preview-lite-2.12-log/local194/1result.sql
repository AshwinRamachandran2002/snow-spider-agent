WITH film_revenue AS (
    SELECT i."film_id", SUM(p."amount") AS "total_revenue"
    FROM "payment" p
    JOIN "rental" r ON p."rental_id" = r."rental_id"
    JOIN "inventory" i ON r."inventory_id" = i."inventory_id"
    GROUP BY i."film_id"
),
film_actor_count AS (
    SELECT "film_id", COUNT(DISTINCT "actor_id") AS "actor_count"
    FROM "film_actor"
    GROUP BY "film_id"
),
film_avg_revenue AS (
    SELECT fr."film_id", fr."total_revenue", fac."actor_count",
           (fr."total_revenue" / fac."actor_count") AS "average_revenue_per_actor"
    FROM film_revenue fr
    JOIN film_actor_count fac ON fr."film_id" = fac."film_id"
),
actor_films AS (
    SELECT a."actor_id", a."first_name" || ' ' || a."last_name" AS "actor_name",
           f."film_id", f."title" AS "film_title"
    FROM "actor" a
    JOIN "film_actor" fa ON a."actor_id" = fa."actor_id"
    JOIN "film" f ON fa."film_id" = f."film_id"
)
SELECT "actor_name", "film_title", ROUND("average_revenue_per_actor", 4) AS "average_revenue_per_actor"
FROM (
    SELECT af."actor_name", af."film_title", far."average_revenue_per_actor",
           ROW_NUMBER() OVER (
               PARTITION BY af."actor_name"
               ORDER BY far."average_revenue_per_actor" DESC
           ) AS "rank"
    FROM actor_films af
    JOIN film_avg_revenue far ON af."film_id" = far."film_id"
)
WHERE "rank" <= 3
ORDER BY "actor_name", "average_revenue_per_actor" DESC;