WITH film_revenue AS (           -- total revenue of each film
       SELECT i.film_id,
              SUM(p.amount) AS film_revenue
       FROM   payment  p
       JOIN   rental   r ON r.rental_id   = p.rental_id
       JOIN   inventory i ON i.inventory_id = r.inventory_id
       GROUP  BY i.film_id
), 
actor_count AS (                 -- actors per film
       SELECT film_id,
              COUNT(*) AS actor_cnt
       FROM   film_actor
       GROUP  BY film_id
),
revenue_per_actor AS (           -- a film’s revenue share for each actor
       SELECT fa.actor_id,
              fa.film_id,
              fr.film_revenue / ac.actor_cnt AS revenue_per_actor
       FROM   film_actor  fa
       JOIN   film_revenue fr ON fr.film_id = fa.film_id
       JOIN   actor_count  ac ON ac.film_id = fa.film_id
),
top3 AS (                        -- rank films by that revenue share
       SELECT rpa.*,
              ROW_NUMBER() OVER (PARTITION BY actor_id
                                 ORDER BY revenue_per_actor DESC) AS rn
       FROM   revenue_per_actor rpa
),
top3_only AS (                   -- keep TOP-3 for every actor
       SELECT *
       FROM   top3
       WHERE  rn <= 3
),
avg_top3 AS (                    -- average of those TOP-3 shares
       SELECT actor_id,
              AVG(revenue_per_actor) AS avg_top3_revenue
       FROM   top3_only
       GROUP  BY actor_id
)
SELECT  a.actor_id,
        a.first_name || ' ' || a.last_name        AS actor_name,
        f.title                                   AS film_title,
        ROUND(t3.revenue_per_actor, 4)            AS revenue_per_actor,
        ROUND(at.avg_top3_revenue, 4)             AS avg_top3_revenue
FROM    top3_only t3
JOIN    actor      a  ON a.actor_id = t3.actor_id
JOIN    film       f  ON f.film_id  = t3.film_id
JOIN    avg_top3   at ON at.actor_id = t3.actor_id
ORDER BY a.actor_id,
         t3.revenue_per_actor DESC,
         f.title;