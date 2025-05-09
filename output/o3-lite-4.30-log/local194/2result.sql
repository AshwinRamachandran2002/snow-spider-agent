WITH film_revenue AS (          -- total revenue earned by each film
    SELECT  i.film_id,
            SUM(p.amount) AS total_revenue
    FROM    payment   p
    JOIN    rental    r ON r.rental_id   = p.rental_id
    JOIN    inventory i ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
actor_count AS (                -- number of actors in each film
    SELECT  film_id,
            COUNT(actor_id) AS num_actors
    FROM    film_actor
    GROUP BY film_id
),
actor_film AS (                 -- link every actor to each of their films with revenue info
    SELECT  a.actor_id,
            a.first_name || ' ' || a.last_name        AS actor_name,
            f.title                                   AS film_title,
            fr.total_revenue,
            fr.total_revenue * 1.0 / ac.num_actors    AS avg_revenue_per_actor
    FROM    film_actor   fa
    JOIN    actor        a  ON a.actor_id = fa.actor_id
    JOIN    film         f  ON f.film_id  = fa.film_id
    JOIN    film_revenue fr ON fr.film_id = f.film_id
    JOIN    actor_count  ac ON ac.film_id = f.film_id
),
ranked AS (                     -- rank films by revenue within each actor’s list
    SELECT  actor_name,
            film_title,
            ROUND(total_revenue,4)         AS total_film_revenue,
            ROUND(avg_revenue_per_actor,4) AS avg_revenue_per_actor,
            ROW_NUMBER() OVER (PARTITION BY actor_name
                               ORDER BY total_revenue DESC, film_title) AS rnk
    FROM    actor_film
)
SELECT  actor_name,
        film_title,
        total_film_revenue,
        avg_revenue_per_actor
FROM    ranked
WHERE   rnk <= 3
ORDER BY actor_name, rnk;