WITH monthly_rentals AS (
    SELECT
        st.store_id,
        strftime('%Y', r.rental_date)  AS year,
        strftime('%m', r.rental_date)  AS month,
        COUNT(*)                       AS total_rentals
    FROM rental AS r
    JOIN staff  AS st ON st.staff_id = r.staff_id          -- rentals “created by the store's staff”
    GROUP BY st.store_id,
             year,
             month
),
ranked AS (
    SELECT
        m.*,
        RANK() OVER (PARTITION BY m.store_id
                     ORDER BY m.total_rentals DESC) AS rnk
    FROM monthly_rentals AS m
)
SELECT
    store_id,
    year,
    month,
    total_rentals
FROM ranked
WHERE rnk = 1                     -- keep only the month‑year(s) with the highest rentals per store
ORDER BY store_id, year, month;