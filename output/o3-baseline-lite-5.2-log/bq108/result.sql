WITH accidents AS (
  -- accidents from Jan‑Aug 2015
  SELECT
    state_number,
    consecutive_number
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE
    month_of_crash BETWEEN 1 AND 8
),
persons AS (
  -- all people in 2015 crashes
  SELECT
    state_number,
    consecutive_number,
    person_number,
    injury_severity
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
),
accident_person_stats AS (
  -- person counts and severe‑injury counts for each accident
  SELECT
    a.state_number,
    a.consecutive_number,
    COUNT(DISTINCT p.person_number)            AS total_persons,
    SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END) AS severe_injuries
  FROM
    accidents AS a
  JOIN
    persons   AS p
  USING (state_number, consecutive_number)
  GROUP BY
    a.state_number, a.consecutive_number
),
eligible_accidents AS (
  -- accidents that involved more than one person
  SELECT *
  FROM accident_person_stats
  WHERE total_persons > 1
)
SELECT
  ROUND(
    100 * SUM(CASE WHEN severe_injuries > 1 THEN 1 ELSE 0 END)
        / COUNT(*)
  , 4) AS percentage_with_multiple_severe_injuries
FROM
  eligible_accidents;