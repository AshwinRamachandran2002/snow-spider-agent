WITH film_revenue AS (          -- total revenue per film
    SELECT  f."film_id",
            SUM(p."amount") AS "total_revenue"
    FROM    "payment"   p
    JOIN    "rental"    r  ON r."rental_id"    = p."rental_id"
    JOIN    "inventory" i  ON i."inventory_id" = r."inventory_id"
    JOIN    "film"      f  ON f."film_id"      = i."film_id"
    GROUP BY f."film_id"
),
actor_share AS (                -- each actor’s equal share in each film
    SELECT  fa."actor_id",
            a."first_name",
            a."last_name",
            fa."film_id",
            f."title",
            fr."total_revenue" / COUNT(DISTINCT fa2."actor_id") AS "actor_share"
    FROM    "film_actor" fa
    JOIN    "actor"      a   ON a."actor_id"  = fa."actor_id"
    JOIN    "film"       f   ON f."film_id"   = fa."film_id"
    JOIN    "film_revenue" fr ON fr."film_id" = f."film_id"
    JOIN    "film_actor"  fa2 ON fa2."film_id" = f."film_id"
    GROUP BY fa."actor_id", fa."film_id"
),
ranked AS (                      -- rank films by share per actor
    SELECT  *,
            RANK() OVER (PARTITION BY "actor_id"
                          ORDER BY "actor_share" DESC) AS "film_rank"
    FROM    actor_share
),
top3 AS (                        -- keep top-3 films for each actor
    SELECT *
    FROM   ranked
    WHERE  "film_rank" <= 3
),
avg_top3 AS (                    -- average share across those top-3 films
    SELECT  "actor_id",
            AVG("actor_share") AS "avg_top3_revenue"
    FROM    top3
    GROUP BY "actor_id"
)
SELECT  t."actor_id",
        t."first_name",
        t."last_name",
        t."film_id",
        t."title",
        ROUND(t."actor_share",4)      AS "actor_share",
        ROUND(a."avg_top3_revenue",4) AS "avg_top3_revenue"
FROM    top3 t
JOIN    avg_top3 a ON a."actor_id" = t."actor_id"
ORDER BY t."actor_id",
         t."actor_share" DESC,
         t."film_id";