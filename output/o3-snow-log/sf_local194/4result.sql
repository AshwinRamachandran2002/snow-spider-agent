WITH film_revenue AS (               -- total revenue earned by each film
    SELECT 
        i."film_id",
        SUM(p."amount") AS "film_revenue"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT   p
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL    r ON p."rental_id" = r."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY i ON r."inventory_id" = i."inventory_id"
    GROUP BY i."film_id"
),
film_actor_count AS (                -- how many actors acted in each film
    SELECT 
        "film_id",
        COUNT("actor_id") AS "actor_count"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR
    GROUP BY "film_id"
),
actor_film_revenue AS (              -- revenue share for every actor-film pair
    SELECT 
        fa."actor_id",
        fa."film_id",
        fr."film_revenue" / fac."actor_count" AS "actor_revenue"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa
    JOIN film_revenue     fr  ON fa."film_id" = fr."film_id"
    JOIN film_actor_count fac ON fa."film_id" = fac."film_id"
),
ranked AS (                          -- rank films by revenue share for each actor
    SELECT
        afr."actor_id",
        afr."film_id",
        f."title",
        afr."actor_revenue",
        ROW_NUMBER() OVER (PARTITION BY afr."actor_id" 
                           ORDER BY afr."actor_revenue" DESC NULLS LAST, afr."film_id") AS "rnk"
    FROM actor_film_revenue afr
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM f ON afr."film_id" = f."film_id"
)
SELECT 
    a."actor_id",
    a."first_name",
    a."last_name",
    r."film_id",
    r."title",
    ROUND(r."actor_revenue", 4) AS "average_revenue_per_actor"
FROM ranked r
JOIN SQLITE_SAKILA.SQLITE_SAKILA.ACTOR a ON r."actor_id" = a."actor_id"
WHERE r."rnk" <= 3                         -- top 3 films per actor
ORDER BY a."actor_id", r."actor_revenue" DESC NULLS LAST, r."film_id";