WITH state_mapping AS (
  SELECT 1 AS state_number, 'Alabama' AS state_name UNION ALL
  SELECT 2, 'Alaska' UNION ALL
  SELECT 4, 'Arizona' UNION ALL
  SELECT 5, 'Arkansas' UNION ALL
  SELECT 6, 'California' UNION ALL
  SELECT 8, 'Colorado' UNION ALL
  SELECT 9, 'Connecticut' UNION ALL
  SELECT 10, 'Delaware' UNION ALL
  SELECT 11, 'District of Columbia' UNION ALL
  SELECT 12, 'Florida' UNION ALL
  SELECT 13, 'Georgia' UNION ALL
  SELECT 15, 'Hawaii' UNION ALL
  SELECT 16, 'Idaho' UNION ALL
  SELECT 17, 'Illinois' UNION ALL
  SELECT 18, 'Indiana' UNION ALL
  SELECT 19, 'Iowa' UNION ALL
  SELECT 20, 'Kansas' UNION ALL
  SELECT 21, 'Kentucky' UNION ALL
  SELECT 22, 'Louisiana' UNION ALL
  SELECT 23, 'Maine' UNION ALL
  SELECT 24, 'Maryland' UNION ALL
  SELECT 25, 'Massachusetts' UNION ALL
  SELECT 26, 'Michigan' UNION ALL
  SELECT 27, 'Minnesota' UNION ALL
  SELECT 28, 'Mississippi' UNION ALL
  SELECT 29, 'Missouri' UNION ALL
  SELECT 30, 'Montana' UNION ALL
  SELECT 31, 'Nebraska' UNION ALL
  SELECT 32, 'Nevada' UNION ALL
  SELECT 33, 'New Hampshire' UNION ALL
  SELECT 34, 'New Jersey' UNION ALL
  SELECT 35, 'New Mexico' UNION ALL
  SELECT 36, 'New York' UNION ALL
  SELECT 37, 'North Carolina' UNION ALL
  SELECT 38, 'North Dakota' UNION ALL
  SELECT 39, 'Ohio' UNION ALL
  SELECT 40, 'Oklahoma' UNION ALL
  SELECT 41, 'Oregon' UNION ALL
  SELECT 42, 'Pennsylvania' UNION ALL
  SELECT 44, 'Rhode Island' UNION ALL
  SELECT 45, 'South Carolina' UNION ALL
  SELECT 46, 'South Dakota' UNION ALL
  SELECT 47, 'Tennessee' UNION ALL
  SELECT 48, 'Texas' UNION ALL
  SELECT 49, 'Utah' UNION ALL
  SELECT 50, 'Vermont' UNION ALL
  SELECT 51, 'Virginia' UNION ALL
  SELECT 53, 'Washington' UNION ALL
  SELECT 54, 'West Virginia' UNION ALL
  SELECT 55, 'Wisconsin' UNION ALL
  SELECT 56, 'Wyoming'
),
state_population AS (
  SELECT 'Alabama' AS state_name, 4779736 AS population UNION ALL
  SELECT 'Alaska', 710231 UNION ALL
  SELECT 'Arizona', 6392017 UNION ALL
  SELECT 'Arkansas', 2915918 UNION ALL
  SELECT 'California', 37253956 UNION ALL
  SELECT 'Colorado', 5029196 UNION ALL
  SELECT 'Connecticut', 3574097 UNION ALL
  SELECT 'Delaware', 897934 UNION ALL
  SELECT 'District of Columbia', 601723 UNION ALL
  SELECT 'Florida', 18801310 UNION ALL
  SELECT 'Georgia', 9687653 UNION ALL
  SELECT 'Hawaii', 1360301 UNION ALL
  SELECT 'Idaho', 1567582 UNION ALL
  SELECT 'Illinois', 12830632 UNION ALL
  SELECT 'Indiana', 6483802 UNION ALL
  SELECT 'Iowa', 3046355 UNION ALL
  SELECT 'Kansas', 2853118 UNION ALL
  SELECT 'Kentucky', 4339367 UNION ALL
  SELECT 'Louisiana', 4533372 UNION ALL
  SELECT 'Maine', 1328361 UNION ALL
  SELECT 'Maryland', 5773552 UNION ALL
  SELECT 'Massachusetts', 6547629 UNION ALL
  SELECT 'Michigan', 9883640 UNION ALL
  SELECT 'Minnesota', 5303925 UNION ALL
  SELECT 'Mississippi', 2967297 UNION ALL
  SELECT 'Missouri', 5988927 UNION ALL
  SELECT 'Montana', 989415 UNION ALL
  SELECT 'Nebraska', 1826341 UNION ALL
  SELECT 'Nevada', 2700551 UNION ALL
  SELECT 'New Hampshire', 1316470 UNION ALL
  SELECT 'New Jersey', 8791894 UNION ALL
  SELECT 'New Mexico', 2059179 UNION ALL
  SELECT 'New York', 19378102 UNION ALL
  SELECT 'North Carolina', 9535483 UNION ALL
  SELECT 'North Dakota', 672591 UNION ALL
  SELECT 'Ohio', 11536504 UNION ALL
  SELECT 'Oklahoma', 3751351 UNION ALL
  SELECT 'Oregon', 3831074 UNION ALL
  SELECT 'Pennsylvania', 12702379 UNION ALL
  SELECT 'Rhode Island', 1052567 UNION ALL
  SELECT 'South Carolina', 4625364 UNION ALL
  SELECT 'South Dakota', 814180 UNION ALL
  SELECT 'Tennessee', 6346105 UNION ALL
  SELECT 'Texas', 25145561 UNION ALL
  SELECT 'Utah', 2763885 UNION ALL
  SELECT 'Vermont', 625741 UNION ALL
  SELECT 'Virginia', 8001024 UNION ALL
  SELECT 'Washington', 6724540 UNION ALL
  SELECT 'West Virginia', 1852994 UNION ALL
  SELECT 'Wisconsin', 5686986 UNION ALL
  SELECT 'Wyoming', 563626
),
distracted_accidents AS (
  SELECT
    '2015' AS Year,
    d.state_number,
    COUNT(DISTINCT d.consecutive_number) AS distracted_accident_count
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015` d
  WHERE
    d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY
    d.state_number
  UNION ALL
  SELECT
    '2016' AS Year,
    d.state_number,
    COUNT(DISTINCT d.consecutive_number) AS distracted_accident_count
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016` d
  WHERE
    d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY
    d.state_number
),
results AS (
  SELECT
    da.Year,
    m.state_name AS State,
    ROUND((da.distracted_accident_count / sp.population) * 100000, 4) AS Accidents_per_100k
  FROM
    distracted_accidents da
  JOIN
    state_mapping m ON da.state_number = m.state_number
  JOIN
    state_population sp ON m.state_name = sp.state_name
)
SELECT
  Year,
  State,
  Accidents_per_100k
FROM
  (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Accidents_per_100k DESC) AS rn
    FROM
      results
  )
WHERE
  rn <= 5
ORDER BY
  Year,
  Accidents_per_100k DESC;