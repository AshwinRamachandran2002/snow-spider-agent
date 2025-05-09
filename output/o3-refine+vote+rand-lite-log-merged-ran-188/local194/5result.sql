WITH film_revenue AS (          -- total revenue for every film
    SELECT  f.film_id,
            SUM(p.amount) AS total_revenue
    FROM    film       AS f
    JOIN    inventory  AS i ON i.film_id   = f.film_id
    JOIN    rental     AS r ON r.inventory_id = i.inventory_id
    JOIN    payment    AS p ON p.rental_id = r.rental_id
    GROUP BY f.film_id
),
actor_count AS (                -- how many actors played in each film
    SELECT  fa.film_id,
            COUNT(DISTINCT fa.actor_id) AS actor_cnt
    FROM    film_actor AS fa
    GROUP BY fa.film_id
),
actor_film_revenue AS (         -- each actor’s share from every film
    SELECT  fa.actor_id,
            fa.film_id,
            1.0 * fr.total_revenue / ac.actor_cnt AS actor_revenue
    FROM    film_actor   AS fa
    JOIN    film_revenue AS fr ON fr.film_id = fa.film_id
    JOIN    actor_count  AS ac ON ac.film_id = fa.film_id
),
ranked AS (                     -- rank films per actor by revenue share
    SELECT  afr.*,
            ROW_NUMBER() OVER (PARTITION BY afr.actor_id
                               ORDER BY afr.actor_revenue DESC) AS rn
    FROM    actor_film_revenue AS afr
),
top3 AS (                       -- keep the best three for every actor
    SELECT *
    FROM   ranked
    WHERE  rn <= 3
),
avg_top3 AS (                   -- average share across those top three
    SELECT  actor_id,
            AVG(actor_revenue) AS avg_revenue_top3
    FROM    top3
    GROUP BY actor_id
)
SELECT  a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        f.title                             AS film_title,
        ROUND(t3.actor_revenue, 4)          AS actor_revenue,
        ROUND(at.avg_revenue_top3, 4)       AS avg_revenue_top3
FROM        top3     AS t3
JOIN        actor    AS a  ON a.actor_id  = t3.actor_id
JOIN        film     AS f  ON f.film_id   = t3.film_id
JOIN        avg_top3 AS at ON at.actor_id = t3.actor_id
ORDER BY    a.actor_id,
            t3.actor_revenue DESC,
            f.title;