SELECT
  Year,
  State,
  ROUND(Accidents_per_100000_people, 4) AS Accidents_per_100000_people
FROM (
  SELECT
    Year,
    State,
    Accidents_per_100000_people,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Accidents_per_100000_people DESC) AS rank
  FROM (
    SELECT
      '2015' AS Year,
      a.state_name AS State,
      (COUNT(DISTINCT d.consecutive_number) / sp.state_population) * 100000 AS Accidents_per_100000_people
    FROM
      `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015` AS d
    JOIN
      `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
    ON
      d.state_number = a.state_number AND d.consecutive_number = a.consecutive_number
    JOIN (
      SELECT
        z.state_name,
        SUM(p.population) AS state_population
      FROM
        `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
      JOIN
        `bigquery-public-data.utility_us.zipcode_area` AS z
      ON
        p.zipcode = z.zipcode
      WHERE
        p.population IS NOT NULL AND z.state_name IS NOT NULL
      GROUP BY
        z.state_name
    ) AS sp
    ON
      a.state_name = sp.state_name
    WHERE
      d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
    GROUP BY
      a.state_name, sp.state_population
    UNION ALL
    SELECT
      '2016' AS Year,
      a.state_name AS State,
      (COUNT(DISTINCT d.consecutive_number) / sp.state_population) * 100000 AS Accidents_per_100000_people
    FROM
      `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016` AS d
    JOIN
      `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
    ON
      d.state_number = a.state_number AND d.consecutive_number = a.consecutive_number
    JOIN (
      SELECT
        z.state_name,
        SUM(p.population) AS state_population
      FROM
        `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
      JOIN
        `bigquery-public-data.utility_us.zipcode_area` AS z
      ON
        p.zipcode = z.zipcode
      WHERE
        p.population IS NOT NULL AND z.state_name IS NOT NULL
      GROUP BY
        z.state_name
    ) AS sp
    ON
      a.state_name = sp.state_name
    WHERE
      d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
    GROUP BY
      a.state_name, sp.state_population
  ) AS calculated_rates
) AS ranked_states
WHERE
  rank <= 5
ORDER BY
  Year,
  Accidents_per_100000_people DESC;