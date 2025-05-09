/* Top three revenue-generating films for each actor, with the actor’s
   average share of the film’s revenue (film revenue divided equally
   among all actors in that film). */
WITH film_rev AS (          -- total revenue per film
    SELECT  i."film_id",
            SUM(p."amount")            AS "film_revenue"
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT   p
    JOIN    SQLITE_SAKILA.SQLITE_SAKILA.RENTAL    r ON p."rental_id"  = r."rental_id"
    JOIN    SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY i ON r."inventory_id" = i."inventory_id"
    GROUP BY i."film_id"
),
actor_cnt AS (              -- number of actors in each film
    SELECT  fa."film_id",
            COUNT(*)        AS "actor_count"
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa
    GROUP BY fa."film_id"
),
actor_film_rev AS (         -- each actor’s share for every film
    SELECT  fa."actor_id",
            fa."film_id",
            COALESCE(fr."film_revenue",0)                    AS "film_revenue",
            COALESCE(fr."film_revenue",0) / ac."actor_count" AS "actor_revenue_share"
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa
    LEFT JOIN film_rev fr  ON fa."film_id" = fr."film_id"
    JOIN      actor_cnt ac ON fa."film_id" = ac."film_id"
),
ranked AS (                 -- rank films per actor by revenue share
    SELECT  afr."actor_id",
            a."first_name",
            a."last_name",
            afr."film_id",
            f."title",
            afr."actor_revenue_share",
            ROW_NUMBER() OVER (PARTITION BY afr."actor_id"
                               ORDER BY afr."actor_revenue_share" DESC NULLS LAST) AS rn
    FROM    actor_film_rev                       afr
    JOIN    SQLITE_SAKILA.SQLITE_SAKILA.ACTOR    a ON afr."actor_id" = a."actor_id"
    JOIN    SQLITE_SAKILA.SQLITE_SAKILA.FILM     f ON afr."film_id"  = f."film_id"
)
SELECT  "actor_id",
        "first_name",
        "last_name",
        "film_id",
        "title",
        ROUND("actor_revenue_share",4) AS "actor_revenue_share"
FROM    ranked
WHERE   rn <= 3
ORDER BY "actor_id", "actor_revenue_share" DESC NULLS LAST, "film_id";