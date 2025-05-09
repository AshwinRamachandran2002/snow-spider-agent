WITH crash_summary AS (
  SELECT
    per.state_number,
    per.consecutive_number,
    COUNT(DISTINCT per.person_number)                        AS people_in_crash,
    COUNTIF(per.injury_severity = 4)                         AS severe_injury_people
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`  AS per
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS acc
    ON  per.state_number       = acc.state_number
   AND  per.consecutive_number = acc.consecutive_number
  WHERE acc.month_of_crash BETWEEN 1 AND 8                       -- January–August
  GROUP BY per.state_number, per.consecutive_number
),
multi_person AS (
  SELECT *
  FROM   crash_summary
  WHERE  people_in_crash > 1                                     -- >1 person involved
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(
            (SELECT COUNT(*) FROM multi_person WHERE severe_injury_people > 1),
            (SELECT COUNT(*) FROM multi_person)
         ),
    4
  ) AS percentage;