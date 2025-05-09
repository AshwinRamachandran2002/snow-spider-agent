WITH rentals_per_month AS (
    SELECT
        s.store_id,
        CAST(strftime('%Y', r.rental_date) AS INTEGER) AS year,
        CAST(strftime('%m', r.rental_date) AS INTEGER) AS month,
        COUNT(*) AS total_rentals
    FROM rental r
    JOIN staff s ON r.staff_id = s.staff_id       -- link each rental to the store where the staff works
    GROUP BY s.store_id, year, month
),
ranked AS (
    SELECT
        store_id,
        year,
        month,
        total_rentals,
        RANK() OVER (PARTITION BY store_id
                     ORDER BY total_rentals DESC, year, month) AS rnk
    FROM rentals_per_month
)
SELECT
    store_id,
    year,
    month,
    total_rentals
FROM ranked
WHERE rnk = 1                -- month(s) with the highest rentals for each store
ORDER BY store_id;