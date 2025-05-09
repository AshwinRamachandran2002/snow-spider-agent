WITH film_revenue AS (            -- total revenue earned by each film
    SELECT  f.film_id,
            SUM(p.amount) AS total_revenue
    FROM    film       AS f
    JOIN    inventory  AS i ON f.film_id      = i.film_id
    JOIN    rental     AS r ON i.inventory_id = r.inventory_id
    JOIN    payment    AS p ON r.rental_id    = p.rental_id
    GROUP BY f.film_id
),
film_actor_count AS (             -- how many distinct actors appear in every film
    SELECT  film_id,
            COUNT(DISTINCT actor_id) AS actor_count
    FROM    film_actor
    GROUP BY film_id
),
actor_film_revenue AS (           -- revenue share (avg per actor) for every (actor, film) pair
    SELECT  a.actor_id,
            a.first_name,
            a.last_name,
            f.film_id,
            f.title,
            fr.total_revenue * 1.0 / fac.actor_count AS avg_revenue_per_actor   -- avoid integer div
    FROM    actor        AS a
    JOIN    film_actor   AS fa  ON a.actor_id = fa.actor_id
    JOIN    film_revenue AS fr  ON fa.film_id = fr.film_id
    JOIN    film_actor_count AS fac ON fa.film_id = fac.film_id
    JOIN    film         AS f   ON fa.film_id = f.film_id
),
ranked AS (                       -- rank films per actor by revenue share
    SELECT  afr.*,
            ROW_NUMBER() OVER (PARTITION BY afr.actor_id
                               ORDER BY afr.avg_revenue_per_actor DESC) AS rn
    FROM    actor_film_revenue AS afr
)
SELECT  actor_id,
        first_name,
        last_name,
        film_id,
        title,
        ROUND(avg_revenue_per_actor, 4) AS avg_revenue_per_actor
FROM    ranked
WHERE   rn <= 3                       -- top 3 films per actor
ORDER BY actor_id, rn;