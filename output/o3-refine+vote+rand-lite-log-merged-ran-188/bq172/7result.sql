WITH ny_drug_totals AS (
  /* 1.  Aggregate 2014 Part‑D claims by drug within New York */
  SELECT
    drug_name,
    SUM(total_claim_count) AS ny_total_claims
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE
    nppes_provider_state = 'NY'
  GROUP BY
    drug_name
),
top_ny_drug AS (
  /* 2.  Identify the single drug with the most NY prescriptions */
  SELECT
    drug_name
  FROM
    ny_drug_totals
  ORDER BY
    ny_total_claims DESC
  LIMIT 1
)
 /* 3.  For that drug, list the five states with the highest claim counts, 
        along with total claim counts and total drug costs */
SELECT
  nppes_provider_state AS state,
  SUM(total_claim_count)  AS total_claims,
  SUM(total_drug_cost)    AS total_drug_cost
FROM
  `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
WHERE
  drug_name IN (SELECT drug_name FROM top_ny_drug)
GROUP BY
  state
ORDER BY
  total_claims DESC
LIMIT 5;