WITH film_revenue AS (
    SELECT
        f."film_id",
        f."title",
        SUM(p."amount") AS "total_revenue"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM" f
        JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" i ON f."film_id" = i."film_id"
        JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r ON i."inventory_id" = r."inventory_id"
        JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p ON r."rental_id" = p."rental_id"
    GROUP BY
        f."film_id",
        f."title"
),
film_actor_count AS (
    SELECT
        fa."film_id",
        COUNT(DISTINCT fa."actor_id") AS "actor_count"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR" fa
    GROUP BY
        fa."film_id"
),
film_avg_revenue_per_actor AS (
    SELECT
        fr."film_id",
        fr."title" AS "film_title",
        fr."total_revenue",
        fac."actor_count",
        (fr."total_revenue" / fac."actor_count") AS "avg_revenue_per_actor"
    FROM
        film_revenue fr
        JOIN film_actor_count fac ON fr."film_id" = fac."film_id"
),
actor_films AS (
    SELECT
        a."actor_id",
        a."first_name" || ' ' || a."last_name" AS "actor_name",
        fa."film_id"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."ACTOR" a
        JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR" fa ON a."actor_id" = fa."actor_id"
),
actor_top_films AS (
    SELECT
        af."actor_id",
        af."actor_name",
        frpa."film_title",
        ROUND(frpa."avg_revenue_per_actor", 4) AS "average_revenue_per_actor",
        ROW_NUMBER() OVER (
            PARTITION BY af."actor_id"
            ORDER BY frpa."avg_revenue_per_actor" DESC NULLS LAST
        ) AS rn
    FROM
        actor_films af
        JOIN film_avg_revenue_per_actor frpa ON af."film_id" = frpa."film_id"
)
SELECT
    "actor_id",
    "actor_name",
    "film_title",
    "average_revenue_per_actor"
FROM
    actor_top_films
WHERE
    rn <= 3
ORDER BY
    "actor_id",
    "average_revenue_per_actor" DESC NULLS LAST;