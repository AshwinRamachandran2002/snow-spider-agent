WITH monthly_rentals AS (
    SELECT  s.store_id,
            strftime('%Y', r.rental_date) AS year,
            strftime('%m', r.rental_date) AS month,
            COUNT(*)                     AS total_rentals
    FROM    rental AS r
    JOIN    staff  AS s USING (staff_id)
    GROUP BY s.store_id, year, month
),
ranked_months AS (
    SELECT  store_id,
            year,
            month,
            total_rentals,
            RANK() OVER (PARTITION BY store_id ORDER BY total_rentals DESC) AS rnk
    FROM    monthly_rentals
)
SELECT  store_id,
        year,
        month,
        total_rentals
FROM    ranked_months
WHERE   rnk = 1
ORDER BY store_id;