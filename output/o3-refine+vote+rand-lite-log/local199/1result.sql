WITH rental_counts AS (
    SELECT
        st.store_id,
        CAST(strftime('%Y', r.rental_date) AS INTEGER) AS year,
        CAST(strftime('%m', r.rental_date) AS INTEGER) AS month,
        COUNT(*) AS total_rentals
    FROM rental            AS r
    JOIN staff             AS st ON st.staff_id = r.staff_id   -- identify the store that each staff member belongs to
    GROUP BY
        st.store_id,
        year,
        month
),
ranked AS (
    SELECT
        store_id,
        year,
        month,
        total_rentals,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY total_rentals DESC, year ASC, month ASC   -- break ties by earliest year‑month
        ) AS rn
    FROM rental_counts
)
SELECT
    store_id,
    year,
    month,
    total_rentals
FROM ranked
WHERE rn = 1
ORDER BY store_id;