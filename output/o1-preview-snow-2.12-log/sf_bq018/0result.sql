SELECT
  TO_CHAR("date", 'MM-DD') AS "Date"
FROM
  COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
WHERE
  "location_key" = 'US'
  AND "date" BETWEEN '2020-03-01' AND '2020-04-30'
  AND "cumulative_confirmed" > 0
ORDER BY
  ("new_confirmed" / "cumulative_confirmed") * 100 DESC NULLS LAST
LIMIT 1;