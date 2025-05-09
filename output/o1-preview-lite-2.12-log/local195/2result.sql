SELECT
  ROUND(((COUNT(DISTINCT r.customer_id) * 1.0) /
   (SELECT COUNT(DISTINCT customer_id) FROM customer)) * 100, 4) AS Percentage_of_Customers
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film_actor fa ON i.film_id = fa.film_id
WHERE fa.actor_id IN (
  SELECT fa.actor_id
  FROM film_actor fa
  JOIN inventory i ON fa.film_id = i.film_id
  JOIN rental r ON i.inventory_id = r.inventory_id
  GROUP BY fa.actor_id
  ORDER BY COUNT(r.rental_id) DESC
  LIMIT 5
);