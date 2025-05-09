WITH drg_leader AS (           -- DRG with the largest number of discharges in 2014
  SELECT
    drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
top3_city_state AS (           -- 3 city‑state combinations with most discharges for that DRG
  SELECT
    provider_city,
    provider_state,
    SUM(total_discharges) AS discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM drg_leader)
  GROUP BY provider_city, provider_state
  ORDER BY discharges DESC
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM drg_leader)           AS drg_definition,
  t.provider_city,
  t.provider_state,
  ROUND( SUM(i.average_total_payments * i.total_discharges)
/        SUM(i.total_discharges), 4)                AS weighted_avg_total_payments
FROM top3_city_state AS t
JOIN `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS i
  ON  i.provider_city  = t.provider_city
  AND i.provider_state = t.provider_state
WHERE i.drg_definition = (SELECT drg_definition FROM drg_leader)
GROUP BY
  t.provider_city,
  t.provider_state
ORDER BY
  SUM(i.total_discharges) DESC;