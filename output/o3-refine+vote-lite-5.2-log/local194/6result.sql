WITH film_revenue AS (          -- total revenue each film has generated
    SELECT  i.film_id,
            SUM(p.amount)        AS total_revenue
    FROM    payment   p
    JOIN    rental    r ON r.rental_id   = p.rental_id
    JOIN    inventory i ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
film_actor_cnt AS (             -- how many actors play in every film
    SELECT  film_id,
            COUNT(*)            AS actor_cnt
    FROM    film_actor
    GROUP BY film_id
),
actor_film_share AS (           -- every actor’s equal share of a film’s revenue
    SELECT  fa.actor_id,
            fa.film_id,
            f.title,
            COALESCE(fr.total_revenue,0) / fac.actor_cnt   AS revenue_per_actor
    FROM    film_actor      fa
    JOIN    film            f   ON f.film_id      = fa.film_id
    JOIN    film_actor_cnt  fac ON fac.film_id    = fa.film_id
    LEFT JOIN film_revenue  fr  ON fr.film_id     = fa.film_id
),
ranked AS (                     -- rank films by revenue share for every actor
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY actor_id
                              ORDER BY revenue_per_actor DESC, film_id) AS rn
    FROM    actor_film_share
)
SELECT  a.actor_id,
        a.first_name,
        a.last_name,
        r.film_id,
        r.title            AS film_title,
        ROUND(r.revenue_per_actor,4) AS revenue_per_actor
FROM    ranked r
JOIN    actor  a ON a.actor_id = r.actor_id
WHERE   r.rn <= 3                             -- top 3 films per actor
ORDER BY a.actor_id,
         r.revenue_per_actor DESC,
         r.film_id;