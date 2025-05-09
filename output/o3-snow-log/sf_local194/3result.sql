/* Top-3 revenue-generating films for every actor
   (actor’s share = total film revenue ÷ number of actors in the film) */
WITH film_revenue AS (         -- total money collected for each film
    SELECT  i."film_id",
            SUM(p."amount")            AS film_revenue
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT   p
    JOIN    SQLITE_SAKILA.SQLITE_SAKILA.RENTAL    r  ON p."rental_id"   = r."rental_id"
    JOIN    SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY i  ON r."inventory_id"= i."inventory_id"
    GROUP BY i."film_id"
),
actor_counts AS (              -- how many actors appeared in every film
    SELECT  "film_id",
            COUNT(DISTINCT "actor_id") AS actors_in_film
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR
    GROUP BY "film_id"
),
actor_film_share AS (          -- each actor’s revenue share per film
    SELECT  fa."actor_id",
            fa."film_id",
            fr.film_revenue / ac.actors_in_film   AS actor_share
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa
    JOIN    film_revenue fr  ON fa."film_id" = fr."film_id"
    JOIN    actor_counts ac  ON fa."film_id" = ac."film_id"
),
ranked AS (                    -- rank films per actor by their share
    SELECT  afs."actor_id",
            f."film_id",
            f."title",
            afs.actor_share,
            ROW_NUMBER() OVER (PARTITION BY afs."actor_id"
                               ORDER BY afs.actor_share DESC NULLS LAST) AS rn
    FROM    actor_film_share afs
    JOIN    SQLITE_SAKILA.SQLITE_SAKILA.FILM f  ON afs."film_id" = f."film_id"
)
SELECT  a."actor_id",
        a."first_name",
        a."last_name",
        r."film_id",
        r."title",
        ROUND(r.actor_share, 4) AS "average_revenue_per_actor"
FROM    ranked r
JOIN    SQLITE_SAKILA.SQLITE_SAKILA.ACTOR a  ON r."actor_id" = a."actor_id"
WHERE   r.rn <= 3
ORDER BY a."actor_id",
         r.actor_share DESC NULLS LAST;