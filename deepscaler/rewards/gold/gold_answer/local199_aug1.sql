-- Task: For each store, list the year, the month, and the total number of rentals.
SELECT
  strftime('%Y', RE.RENTAL_DATE) AS YEAR,
  strftime('%m', RE.RENTAL_DATE) AS RENTAL_MONTH,
  ST.STORE_ID,
  COUNT(RE.RENTAL_ID) AS total_rentals
FROM
  RENTAL RE
  JOIN STAFF ST ON RE.STAFF_ID = ST.STAFF_ID
GROUP BY
  YEAR,
  RENTAL_MONTH,
  ST.STORE_ID
ORDER BY
  ST.STORE_ID, YEAR, RENTAL_MONTH;