WITH
    film_total_revenue AS (
        SELECT
            F."film_id",
            F."title",
            SUM(P."amount") AS "total_revenue"
        FROM
            SQLITE_SAKILA.SQLITE_SAKILA.FILM F
            JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY I ON F."film_id" = I."film_id"
            JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL R ON I."inventory_id" = R."inventory_id"
            JOIN SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT P ON R."rental_id" = P."rental_id"
        GROUP BY F."film_id", F."title"
    ),
    film_actor_count AS (
        SELECT
            FA."film_id",
            COUNT(DISTINCT FA."actor_id") AS "num_actors"
        FROM
            SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR FA
        GROUP BY FA."film_id"
    ),
    film_revenue AS (
        SELECT
            FTR."film_id",
            FTR."title",
            FTR."total_revenue",
            FAC."num_actors",
            (FTR."total_revenue" / FAC."num_actors") AS "average_revenue_per_actor"
        FROM
            film_total_revenue FTR
            JOIN film_actor_count FAC ON FTR."film_id" = FAC."film_id"
    ),
    actor_films AS (
        SELECT
            A."actor_id",
            A."first_name",
            A."last_name",
            FA."film_id"
        FROM
            SQLITE_SAKILA.SQLITE_SAKILA.ACTOR A
            JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR FA ON A."actor_id" = FA."actor_id"
    ),
    actor_film_revenue AS (
        SELECT
            AF."actor_id",
            AF."first_name",
            AF."last_name",
            FR."film_id",
            FR."title" AS "film_title",
            FR."total_revenue",
            FR."average_revenue_per_actor"
        FROM
            actor_films AF
            JOIN film_revenue FR ON AF."film_id" = FR."film_id"
    ),
    actor_top_films AS (
        SELECT
            AF."actor_id",
            AF."first_name",
            AF."last_name",
            AF."film_id",
            AF."film_title",
            AF."average_revenue_per_actor",
            AF."total_revenue",
            ROW_NUMBER() OVER (
                PARTITION BY AF."actor_id"
                ORDER BY AF."total_revenue" DESC NULLS LAST, AF."film_title"
            ) AS "rn"
        FROM
            actor_film_revenue AF
    )
SELECT
    ATF."actor_id",
    ATF."first_name" || ' ' || ATF."last_name" AS "actor_name",
    ATF."film_title",
    ROUND(ATF."average_revenue_per_actor", 4) AS "average_revenue_per_actor"
FROM
    actor_top_films ATF
WHERE
    ATF."rn" <= 3
ORDER BY
    ATF."actor_id",
    ATF."average_revenue_per_actor" DESC;