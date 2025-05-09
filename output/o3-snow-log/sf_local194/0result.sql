/*  Top-3 revenue-generating films for every actor                               */
/*  “Average revenue per actor” = (total film revenue) / (# actors in the film) */

WITH film_revenue AS (        -- total revenue earned by each film
    SELECT
        i."film_id",
        SUM(p."amount") AS total_revenue
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT    p
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL     r  ON p."rental_id"   = r."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY  i  ON r."inventory_id" = i."inventory_id"
    GROUP BY i."film_id"
),

actor_count AS (              -- number of actors appearing in each film
    SELECT
        "film_id",
        COUNT(DISTINCT "actor_id") AS actor_cnt
    FROM SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR
    GROUP BY "film_id"
),

film_revenue_per_actor AS (   -- revenue share for one actor in a given film
    SELECT
        fr."film_id",
        fr.total_revenue,
        ac.actor_cnt,
        fr.total_revenue / ac.actor_cnt AS revenue_per_actor
    FROM film_revenue fr
    JOIN actor_count  ac  ON fr."film_id" = ac."film_id"
),

actor_film_revenue AS (       -- attach each actor to his/her per-film revenue
    SELECT
        fa."actor_id",
        fa."film_id",
        f."title",
        fpa.revenue_per_actor
    FROM SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa
    JOIN film_revenue_per_actor                fpa ON fa."film_id" = fpa."film_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM      f   ON fa."film_id" = f."film_id"
),

ranked AS (                   -- rank films by revenue share within each actor
    SELECT
        afr.*,
        ROW_NUMBER() OVER (PARTITION BY afr."actor_id"
                           ORDER BY afr.revenue_per_actor DESC NULLS LAST) AS rn
    FROM actor_film_revenue afr
)

SELECT
    a."actor_id",
    a."first_name",
    a."last_name",
    r."film_id",
    r."title",
    ROUND(r.revenue_per_actor, 4) AS revenue_per_actor
FROM ranked                        r
JOIN SQLITE_SAKILA.SQLITE_SAKILA.ACTOR a
     ON r."actor_id" = a."actor_id"
WHERE r.rn <= 3                    -- top-3 films per actor
ORDER BY a."actor_id",
         r.revenue_per_actor DESC NULLS LAST,
         r."film_id";