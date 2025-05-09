WITH store_rentals AS (
  SELECT
    s."store_id" AS "Store_ID",
    CAST(strftime('%Y', r."rental_date") AS INTEGER) AS "Year",
    CAST(strftime('%m', r."rental_date") AS INTEGER) AS "Month",
    COUNT(*) AS "Total_Rentals"
  FROM
    "rental" AS r
  JOIN
    "staff" AS s ON r."staff_id" = s."staff_id"
  GROUP BY
    s."store_id",
    "Year",
    "Month"
),
max_rentals AS (
  SELECT
    "Store_ID",
    MAX("Total_Rentals") AS "Max_Total_Rentals"
  FROM
    store_rentals
  GROUP BY
    "Store_ID"
)
SELECT
  sr."Store_ID",
  sr."Year",
  sr."Month",
  sr."Total_Rentals"
FROM
  store_rentals sr
JOIN
  max_rentals mr ON sr."Store_ID" = mr."Store_ID" AND sr."Total_Rentals" = mr."Max_Total_Rentals"
ORDER BY
  sr."Store_ID";