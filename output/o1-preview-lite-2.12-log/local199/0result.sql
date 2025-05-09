SELECT t1.store_id, t1.year, t1.month, t1.total_rentals
FROM (
    SELECT staff.store_id AS store_id,
           CAST(strftime('%Y', rental.rental_date) AS INTEGER) AS year,
           CAST(strftime('%m', rental.rental_date) AS INTEGER) AS month,
           COUNT(*) AS total_rentals
    FROM rental
    JOIN staff ON rental.staff_id = staff.staff_id
    GROUP BY staff.store_id, year, month
) t1
JOIN (
    SELECT store_id,
           MAX(total_rentals) AS max_total_rentals
    FROM (
        SELECT staff.store_id AS store_id,
               CAST(strftime('%Y', rental.rental_date) AS INTEGER) AS year,
               CAST(strftime('%m', rental.rental_date) AS INTEGER) AS month,
               COUNT(*) AS total_rentals
        FROM rental
        JOIN staff ON rental.staff_id = staff.staff_id
        GROUP BY staff.store_id, year, month
    ) t2
    GROUP BY store_id
) t3 ON t1.store_id = t3.store_id AND t1.total_rentals = t3.max_total_rentals
ORDER BY t1.store_id;