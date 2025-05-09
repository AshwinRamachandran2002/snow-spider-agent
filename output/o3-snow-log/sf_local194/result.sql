WITH "film_revenue" AS (          -- total revenue earned by each film
    SELECT 
        i."film_id",
        SUM(p."amount") AS "film_revenue"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT"   p
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."RENTAL"    r ON p."rental_id"   = r."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY" i ON r."inventory_id" = i."inventory_id"
    GROUP BY i."film_id"
),
"actor_count" AS (                -- number of actors that played in each film
    SELECT 
        fa."film_id",
        COUNT(fa."actor_id") AS "actor_count"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."FILM_ACTOR" fa
    GROUP BY fa."film_id"
),
"actor_film_revenue" AS (         -- revenue share per actor for each film
    SELECT 
        fa."actor_id",
        fa."film_id",
        fr."film_revenue" / ac."actor_count" AS "actor_share"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."FILM_ACTOR" fa
    JOIN "film_revenue" fr ON fa."film_id" = fr."film_id"
    JOIN "actor_count"  ac ON fa."film_id" = ac."film_id"
),
"ranked" AS (                     -- rank the films per actor by individual share
    SELECT
        afr."actor_id",
        afr."film_id",
        afr."actor_share",
        ROW_NUMBER() OVER (
            PARTITION BY afr."actor_id"
            ORDER BY afr."actor_share" DESC NULLS LAST
        ) AS "rn"
    FROM "actor_film_revenue" afr
)
SELECT
    a."actor_id",
    a."first_name",
    a."last_name",
    f."film_id",
    f."title",
    ROUND(r."actor_share", 4) AS "average_revenue_per_actor"
FROM "ranked" r
JOIN SQLITE_SAKILA.SQLITE_SAKILA."ACTOR" a ON r."actor_id" = a."actor_id"
JOIN SQLITE_SAKILA.SQLITE_SAKILA."FILM"  f ON r."film_id"  = f."film_id"
WHERE r."rn" <= 3                             -- top 3 films for each actor
ORDER BY a."actor_id",
         "average_revenue_per_actor" DESC NULLS LAST;