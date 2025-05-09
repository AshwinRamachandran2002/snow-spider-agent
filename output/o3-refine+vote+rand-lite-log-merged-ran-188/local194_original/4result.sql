WITH film_revenue AS (               -- total revenue each film generated
    SELECT  i.film_id,
            SUM(p.amount) AS total_revenue
    FROM    payment  AS p
    JOIN    rental   AS r ON p.rental_id  = r.rental_id
    JOIN    inventory AS i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
),
actors_per_film AS (                 -- number of actors in every film
    SELECT  film_id,
            COUNT(*) AS actor_cnt
    FROM    film_actor
    GROUP BY film_id
),
film_actor_revenue AS (              -- revenue share of every actor in every film
    SELECT  fa.actor_id,
            fa.film_id,
            fr.total_revenue,
            fr.total_revenue * 1.0 / ap.actor_cnt AS revenue_per_actor
    FROM    film_actor       AS fa
    JOIN    film_revenue     AS fr ON fa.film_id = fr.film_id
    JOIN    actors_per_film  AS ap ON fa.film_id = ap.film_id
),
ranked AS (                          -- rank films by revenue for each actor
    SELECT  far.*,
            ROW_NUMBER() OVER (PARTITION BY actor_id
                               ORDER BY total_revenue DESC, film_id) AS rn
    FROM    film_actor_revenue AS far
),
top3 AS (                            -- keep only the top‑three films per actor
    SELECT *
    FROM   ranked
    WHERE  rn <= 3
),
avg_revenue AS (                     -- average revenue share across the top‑three films
    SELECT  actor_id,
            AVG(revenue_per_actor) AS avg_revenue_top3
    FROM    top3
    GROUP BY actor_id
)
SELECT  a.actor_id,
        a.first_name,
        a.last_name,
        f.film_id,
        f.title,
        ROUND(t.revenue_per_actor, 4) AS revenue_per_actor,
        ROUND(ar.avg_revenue_top3, 4) AS avg_revenue_top3
FROM    top3          AS t
JOIN    film          AS f  ON t.film_id  = f.film_id
JOIN    actor         AS a  ON t.actor_id = a.actor_id
JOIN    avg_revenue   AS ar ON t.actor_id = ar.actor_id
ORDER BY a.actor_id,
         t.total_revenue DESC,
         f.film_id;