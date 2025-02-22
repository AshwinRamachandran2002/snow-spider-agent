-- Task: For the country with country_code_2 'ir' in the 'cities' table, which had data inserted on nine different days in January 2022, find the longest consecutive period of data insertions during January 2022. Then, calculate the proportion of entries from its capital city (where "capital" = 1) during this longest consecutive insertion period.
WITH
  insertion_dates AS (
    SELECT DISTINCT insert_date
    FROM cities
    WHERE country_code_2 = 'ir' AND insert_date LIKE '2022-01-%'
  ),
  datediff AS (
    SELECT insert_date,
    julianday(insert_date) - julianday('2022-01-01') AS day_number
    FROM insertion_dates
  ),
  consecutive_periods AS (
    SELECT insert_date, day_number,
    day_number - ROW_NUMBER() OVER (ORDER BY day_number) AS grp
    FROM datediff
  ),
  periods AS (
    SELECT grp, MIN(insert_date) AS start_date, MAX(insert_date) AS end_date, COUNT(*) AS days_length
    FROM consecutive_periods
    GROUP BY grp
  ),
  max_length AS (
    SELECT MAX(days_length) AS max_days
    FROM periods
  ),
  longest_period AS (
    SELECT start_date, end_date, days_length
    FROM periods
    WHERE days_length = (SELECT max_days FROM max_length)
  )
SELECT
  ROUND(CAST(SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*), 4) AS proportion_of_entries_from_capital
FROM cities
WHERE country_code_2 = 'ir'
  AND insert_date BETWEEN (SELECT start_date FROM longest_period) AND (SELECT end_date FROM longest_period);