-- Task: Find the top 5 actors based on the number of times their films have been rented.
SELECT fa.actor_id, COUNT(r.rental_id) AS rental_count
FROM film_actor fa
JOIN inventory i ON fa.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY fa.actor_id
ORDER BY rental_count DESC
LIMIT 5;