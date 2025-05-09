WITH film_revenue AS (                    -- total revenue per film
    SELECT  i."film_id",
            SUM(p."amount") AS total_rev
    FROM    "payment"  p
    JOIN    "rental"   r ON r."rental_id"   = p."rental_id"
    JOIN    "inventory" i ON i."inventory_id" = r."inventory_id"
    GROUP   BY i."film_id"
), actor_count AS (                       -- how many actors in each film
    SELECT  "film_id",
            COUNT(DISTINCT "actor_id") AS cnt_actors
    FROM    "film_actor"
    GROUP   BY "film_id"
), actor_film_share AS (                  -- each actor’s share for every film
    SELECT  fa."actor_id",
            fa."film_id",
            f."title",
            fr.total_rev / ac.cnt_actors  AS actor_share
    FROM    "film_actor" fa
    JOIN    film_revenue  fr ON fr."film_id" = fa."film_id"
    JOIN    actor_count   ac ON ac."film_id" = fa."film_id"
    JOIN    "film"        f  ON f."film_id"  = fa."film_id"
), ranked AS (                            -- rank films within each actor
    SELECT  afs.*,
            ROW_NUMBER() OVER (PARTITION BY afs."actor_id"
                               ORDER BY afs.actor_share DESC) AS rn
    FROM    actor_film_share afs
)
SELECT  a."actor_id",
        a."first_name" || ' ' || a."last_name" AS actor_name,
        r."title"  AS film_title,
        ROUND(r.actor_share, 2) AS avg_revenue_for_actor
FROM    ranked r
JOIN    "actor" a ON a."actor_id" = r."actor_id"
WHERE   r.rn <= 3
ORDER   BY a."actor_id",
          r.actor_share DESC,
          r."title";