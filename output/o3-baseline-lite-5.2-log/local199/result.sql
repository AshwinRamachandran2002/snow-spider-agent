WITH rental_counts AS (
    SELECT
        s.store_id                                         AS store_id,
        CAST(strftime('%Y', r.rental_date) AS INTEGER)     AS year,
        CAST(strftime('%m', r.rental_date) AS INTEGER)     AS month,
        COUNT(*)                                           AS total_rentals
    FROM rental  r
    JOIN staff   s ON r.staff_id = s.staff_id            -- relate rental to the store through staff
    GROUP BY
        s.store_id,
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
            ORDER BY total_rentals DESC, year, month      -- if tied, keep earliest year‑month
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