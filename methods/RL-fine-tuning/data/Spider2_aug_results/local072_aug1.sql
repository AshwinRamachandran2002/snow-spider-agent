-- Task: Identify the periods of consecutive data insertions for country 'ir' during January 2022, listing the start and end dates of each period and their lengths.
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
  )
SELECT start_date, end_date, days_length
FROM periods;