WITH rental_counts AS (
    /* rentals made by each store’s staff, aggregated by year‑month */
    SELECT  s.store_id,
            CAST(strftime('%Y', r.rental_date) AS INTEGER)  AS year,
            CAST(strftime('%m', r.rental_date) AS INTEGER)  AS month,
            COUNT(*)                                       AS total_rentals
    FROM    rental  r
    JOIN    staff   s  ON r.staff_id = s.staff_id          -- be sure the rental was created by that store’s staff
    GROUP BY s.store_id, year, month
),
ranked AS (
    /* rank the year‑month rows inside every store by descending rentals,
       then by earliest year / month to resolve possible ties */
    SELECT  rc.*,
            ROW_NUMBER() OVER (PARTITION BY rc.store_id
                               ORDER BY rc.total_rentals DESC,
                                        rc.year,
                                        rc.month) AS rn
    FROM    rental_counts rc
)
SELECT  store_id,
        year,
        month,
        total_rentals
FROM    ranked
WHERE   rn = 1                      -- highest‑rental month for each store
ORDER BY store_id;