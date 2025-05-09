WITH film_revenue AS (
    SELECT
        f."film_id",
        f."title" AS "film_title",
        SUM(p."amount") AS "total_revenue"
    FROM "film" f
    JOIN "inventory"  i ON i."film_id"      = f."film_id"
    JOIN "rental"     r ON r."inventory_id" = i."inventory_id"
    JOIN "payment"    p ON p."rental_id"    = r."rental_id"
    GROUP BY f."film_id"
),
actor_count AS (
    SELECT
        fa."film_id",
        COUNT(DISTINCT fa."actor_id") AS "actor_cnt"
    FROM "film_actor" fa
    GROUP BY fa."film_id"
),
actor_film_rev AS (
    SELECT
        a."actor_id",
        a."first_name" || ' ' || a."last_name" AS "actor_name",
        fr."film_title",
        fr."total_revenue",
        fr."total_revenue" / ac."actor_cnt"    AS "avg_revenue_per_actor"
    FROM "actor"      a
    JOIN "film_actor" fa ON fa."actor_id" = a."actor_id"
    JOIN film_revenue fr ON fr."film_id"  = fa."film_id"
    JOIN actor_count  ac ON ac."film_id"  = fr."film_id"
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "actor_id"
                           ORDER BY "total_revenue" DESC, "film_title") AS rn
    FROM actor_film_rev
)
SELECT
    "actor_name",
    "film_title",
    ROUND("total_revenue", 4)         AS "total_film_revenue",
    ROUND("avg_revenue_per_actor",4)  AS "avg_revenue_per_actor"
FROM ranked
WHERE rn <= 3
ORDER BY "actor_name", "total_film_revenue" DESC, "film_title";