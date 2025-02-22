-- Task: Find the name of the female baby born in Wyoming in 2021 that accounted for the highest percentage of its total number of births across all states in that year.
SELECT
  a.name AS name
FROM
  `bigquery-public-data.usa_names.usa_1910_current` a
JOIN (
  SELECT
    name,
    gender,
    year,
    SUM(number) AS total_number
  FROM
    `bigquery-public-data.usa_names.usa_1910_current`
  GROUP BY
    name,
    gender,
    year) b
ON
  a.name = b.name
  AND a.gender = b.gender
  AND a.year = b.year
WHERE 
    a.gender = 'F' AND
    a.state = 'WY' AND
    a.year = 2021
ORDER BY (a.number / b.total_number) DESC
LIMIT 1