WITH film_rev AS (
    SELECT  i.film_id,
            SUM(p.amount)                 AS total_revenue
    FROM    payment   AS p
    JOIN    rental    AS r ON p.rental_id   = r.rental_id
    JOIN    inventory AS i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
),
actor_cnt AS (
    SELECT  film_id,
            COUNT(DISTINCT actor_id)      AS num_actors
    FROM    film_actor
    GROUP BY film_id
),
actor_film AS (
    SELECT  fa.actor_id,
            fa.film_id,
            fr.total_revenue * 1.0 / ac.num_actors   AS actor_share,
            ROW_NUMBER() OVER (PARTITION BY fa.actor_id
                               ORDER BY fr.total_revenue * 1.0 / ac.num_actors DESC) AS rk
    FROM    film_actor AS fa
    JOIN    film_rev   AS fr ON fa.film_id = fr.film_id
    JOIN    actor_cnt  AS ac ON fa.film_id = ac.film_id
),
top3 AS (
    SELECT *
    FROM   actor_film
    WHERE  rk <= 3
)
SELECT  a.actor_id,
        a.first_name,
        a.last_name,
        f.title                                     AS film_title,
        ROUND(t.actor_share, 4)                     AS actor_revenue,
        ROUND(AVG(t.actor_share) OVER (PARTITION BY a.actor_id), 4) AS avg_top3_revenue
FROM    top3  AS t
JOIN    actor AS a ON t.actor_id = a.actor_id
JOIN    film  AS f ON t.film_id  = f.film_id
ORDER BY a.actor_id, t.actor_share DESC;