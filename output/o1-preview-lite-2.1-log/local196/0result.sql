WITH first_rentals AS (
    SELECT 
        r.customer_id,
        r.rental_id,
        r.inventory_id,
        r.rental_date,
        ROW_NUMBER() OVER (PARTITION BY r.customer_id ORDER BY r.rental_date, r.rental_id) AS rn
    FROM rental r
),
customer_first_rental AS (
    SELECT 
        fr.customer_id, 
        fr.rental_id AS first_rental_id, 
        fr.inventory_id AS first_inventory_id, 
        fr.rental_date AS first_rental_date
        FROM first_rentals fr
    WHERE fr.rn = 1
),
customer_data AS (
    SELECT 
        cfr.customer_id,
        cfr.first_rental_id,
        cfr.first_rental_date,
        f.rating AS first_rating
    FROM customer_first_rental cfr
    JOIN inventory i ON cfr.first_inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
),
customer_total_spend AS (
    SELECT customer_id, SUM(amount) AS total_spend
    FROM payment
    GROUP BY customer_id
),
customer_subsequent_rentals AS (
    SELECT 
        r.customer_id, 
        COUNT(*) AS num_subsequent_rentals
    FROM rental r
    JOIN customer_first_rental cfr ON r.customer_id = cfr.customer_id
    WHERE (r.rental_date > cfr.first_rental_date) OR (r.rental_date = cfr.first_rental_date AND r.rental_id > cfr.first_rental_id)
    GROUP BY r.customer_id
)
SELECT 
    cd.first_rating AS Rating,
    ROUND(AVG(IFNULL(cts.total_spend, 0)), 4) AS Average_Total_Spend,
    ROUND(AVG(IFNULL(csr.num_subsequent_rentals, 0)), 4) AS Average_Number_of_Subsequent_Rentals
FROM customer_data cd
LEFT JOIN customer_total_spend cts ON cd.customer_id = cts.customer_id
LEFT JOIN customer_subsequent_rentals csr ON cd.customer_id = csr.customer_id
GROUP BY cd.first_rating;