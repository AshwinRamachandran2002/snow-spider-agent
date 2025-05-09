WITH rentals_per_month AS (
    SELECT  s.store_id                                       AS store_id,
            strftime('%Y', r.rental_date)                    AS year,
            strftime('%m', r.rental_date)                    AS month,
            COUNT(*)                                         AS total_rentals
    FROM   rental  AS r
    JOIN   staff   AS s   ON r.staff_id = s.staff_id
    GROUP  BY s.store_id, year, month
),
max_per_store AS (
    SELECT  store_id,
            MAX(total_rentals) AS max_total
    FROM    rentals_per_month
    GROUP   BY store_id
)
SELECT  rpm.store_id,
        rpm.year,
        rpm.month,
        rpm.total_rentals
FROM    rentals_per_month AS rpm
JOIN    max_per_store     AS mps
      ON rpm.store_id     = mps.store_id
     AND rpm.total_rentals = mps.max_total
ORDER BY rpm.store_id, rpm.year, rpm.month;