WITH rental_per_month AS (
    SELECT
        s.store_id,
        CAST(strftime('%Y', r.rental_date) AS INTEGER)  AS year,
        CAST(strftime('%m', r.rental_date) AS INTEGER)  AS month,
        COUNT(*)                                        AS total_rentals
    FROM rental  r
    JOIN staff   s ON s.staff_id = r.staff_id          -- rentals handled by each store's staff
    GROUP BY
        s.store_id,
        year,
        month
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY total_rentals DESC, year ASC, month ASC
        ) AS rn
    FROM rental_per_month
)
SELECT
    store_id,
    year,
    month,
    total_rentals
FROM ranked
WHERE rn = 1
ORDER BY store_id;