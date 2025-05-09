WITH most_common_diagnosis AS (
  SELECT drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
top_cities AS (
  SELECT provider_city
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` ic
  JOIN most_common_diagnosis mcd ON ic.drg_definition = mcd.drg_definition
  GROUP BY provider_city
  ORDER BY SUM(ic.total_discharges) DESC
  LIMIT 3
)
SELECT ic.provider_city AS city_name, ROUND(AVG(ic.average_total_payments), 4) AS average_payment
FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` ic
JOIN most_common_diagnosis mcd ON ic.drg_definition = mcd.drg_definition
WHERE ic.provider_city IN (SELECT provider_city FROM top_cities)
GROUP BY ic.provider_city
ORDER BY average_payment DESC;