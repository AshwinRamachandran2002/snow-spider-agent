WITH first_rentals AS (
   SELECT r.customer_id, r.rental_date, i.film_id, f.rating
   FROM rental r
   JOIN (
       SELECT customer_id, MIN(rental_date) AS first_rental_date
       FROM rental
       GROUP BY customer_id
   ) fr ON r.customer_id = fr.customer_id AND r.rental_date = fr.first_rental_date
   JOIN inventory i ON r.inventory_id = i.inventory_id
   JOIN film f ON i.film_id = f.film_id
),
customer_total_spend AS (
  SELECT customer_id, SUM(amount) AS total_spent
  FROM payment
  GROUP BY customer_id
),
customer_rental_counts AS (
  SELECT customer_id, COUNT(*) AS total_rentals
  FROM rental
  GROUP BY customer_id
)
SELECT
  fr.rating AS "Rating",
  ROUND(AVG(cts.total_spent), 4) AS "Average_Total_Spend",
  ROUND(AVG(crc.total_rentals - 1), 4) AS "Average_Number_of_Subsequent_Rentals"
FROM
  first_rentals fr
  JOIN customer_total_spend cts ON fr.customer_id = cts.customer_id
  JOIN customer_rental_counts crc ON fr.customer_id = crc.customer_id
GROUP BY
  fr.rating
ORDER BY
  fr.rating;