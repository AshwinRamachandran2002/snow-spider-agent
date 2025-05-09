WITH rental_with_store AS (
    SELECT
        st.store_id,
        r.rental_date
    FROM rental r
    JOIN staff st ON st.staff_id = r.staff_id
),
monthly_counts AS (
    SELECT
        store_id,
        CAST(strftime('%Y', rental_date) AS INTEGER) AS year,
        CAST(strftime('%m', rental_date) AS INTEGER) AS month,
        COUNT(*) AS total_rentals
    FROM rental_with_store
    GROUP BY store_id, year, month
),
ranked AS (
    SELECT
        mc.*,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY total_rentals DESC,
                     year,
                     month
        ) AS rn
    FROM monthly_counts mc
)
SELECT
    store_id,
    year,
    month,
    total_rentals
FROM ranked
WHERE rn = 1
ORDER BY store_id;