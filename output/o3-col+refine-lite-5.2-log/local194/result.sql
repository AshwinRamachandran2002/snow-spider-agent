WITH film_revenue AS (          -- 1. revenue & actor‑count for every film
    SELECT  f."film_id",
            f."title",
            SUM(p."amount")                      AS "total_revenue",
            COUNT(DISTINCT fa2."actor_id")       AS "actor_count"
    FROM    "payment"    AS p
    JOIN    "rental"     AS r  USING ("rental_id")
    JOIN    "inventory"  AS i  USING ("inventory_id")
    JOIN    "film"       AS f  USING ("film_id")
    JOIN    "film_actor" AS fa2 USING ("film_id")
    GROUP   BY f."film_id"
),
actor_films AS (              -- 2. give each actor a pro‑rata share per film
    SELECT  a."actor_id",
            a."first_name" || ' ' || a."last_name"      AS "actor_name",
            fr."film_id",
            fr."title",
            fr."total_revenue",
            1.0 * fr."total_revenue" / fr."actor_count" AS "revenue_per_actor"
    FROM    "actor"      AS a
    JOIN    "film_actor" AS fa  ON a."actor_id" = fa."actor_id"
    JOIN    film_revenue  fr    ON fr."film_id" = fa."film_id"
),
ranked AS (                   -- 3. rank films by revenue for each actor
    SELECT  af.*,
            ROW_NUMBER() OVER (
                PARTITION BY af."actor_id"
                ORDER BY     af."total_revenue" DESC, af."film_id"
            ) AS "film_rank"
    FROM    actor_films AS af
),
top3 AS (                      -- 4. keep only the top‑3 films
    SELECT *
    FROM   ranked
    WHERE  "film_rank" <= 3
)
SELECT
       "actor_id",
       "actor_name",
       "film_id",
       "title",
       ROUND("revenue_per_actor", 4)                        AS "revenue_per_actor",
       ROUND(AVG("revenue_per_actor") OVER (
                 PARTITION BY "actor_id"), 4)               AS "avg_revenue_top3"
FROM   top3
ORDER  BY "actor_id", "film_rank";