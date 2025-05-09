WITH ActorFilmRevenue AS (
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        f.title AS film_title,
        SUM(p.amount) / COUNT(DISTINCT fa2.actor_id) AS average_revenue_per_actor
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    JOIN film_actor fa2 ON f.film_id = fa2.film_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY a.actor_id, f.film_id
),
RankedFilms AS (
    SELECT
        actor_id,
        actor_name,
        film_title,
        average_revenue_per_actor,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY average_revenue_per_actor DESC) AS revenue_rank
    FROM ActorFilmRevenue
)
SELECT actor_name, film_title, ROUND(average_revenue_per_actor, 4) AS average_revenue_per_actor
FROM RankedFilms
WHERE revenue_rank <= 3
ORDER BY actor_name, average_revenue_per_actor DESC;