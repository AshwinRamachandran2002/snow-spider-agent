SELECT store_id, year, month, total_rentals
FROM (
    SELECT s.store_id,
           CAST(strftime('%Y', r.rental_date) AS INTEGER) AS year,
           CAST(strftime('%m', r.rental_date) AS INTEGER) AS month,
           COUNT(*) AS total_rentals,
           RANK() OVER (PARTITION BY s.store_id ORDER BY COUNT(*) DESC) AS rk
    FROM rental AS r
    JOIN staff AS s ON r.staff_id = s.staff_id
    GROUP BY s.store_id, year, month
)
WHERE rk = 1;