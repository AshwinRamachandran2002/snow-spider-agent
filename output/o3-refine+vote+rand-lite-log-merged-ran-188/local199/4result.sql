WITH rental_store AS (
    -- link every rental to the store of the staff member who handled it
    SELECT
        st.store_id,
        r.rental_date
    FROM rental  r
    JOIN staff   st ON st.staff_id = r.staff_id
),
monthly_totals AS (
    -- count rentals per store, per calendar year & month
    SELECT
        store_id,
        CAST(strftime('%Y', rental_date) AS INTEGER) AS year,
        CAST(strftime('%m', rental_date) AS INTEGER) AS month,
        COUNT(*) AS total_rentals
    FROM rental_store
    GROUP BY store_id,
             year,
             month
),
max_per_store AS (
    -- find the highest monthly total for each store
    SELECT
        store_id,
        MAX(total_rentals) AS max_rentals
    FROM monthly_totals
    GROUP BY store_id
)
-- return the year‑month(s) with that maximum for every store
SELECT
    mt.store_id,
    mt.year,
    mt.month,
    mt.total_rentals
FROM monthly_totals mt
JOIN max_per_store mp
  ON mt.store_id = mp.store_id
 AND mt.total_rentals = mp.max_rentals
ORDER BY mt.store_id,
         mt.year,
         mt.month;