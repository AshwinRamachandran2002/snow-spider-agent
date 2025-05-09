WITH inpatient AS (
  SELECT
    npi,
    SUM(average_medicare_allowed_amt) AS inpatient_avg_allowed
  FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
  WHERE hcpcs_code BETWEEN '99221' AND '99239'        -- classic inpatient E&M codes
  GROUP BY npi
),
outpatient AS (
  SELECT
    npi,
    SUM(average_medicare_allowed_amt) AS outpatient_avg_allowed
  FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
  WHERE hcpcs_code BETWEEN '99201' AND '99215'        -- classic outpatient E&M codes
  GROUP BY npi
),
combined AS (
  SELECT
    i.npi,
    ANY_VALUE(p.nppes_provider_last_org_name)  AS last_name,
    ANY_VALUE(p.nppes_provider_first_name)     AS first_name,
    i.inpatient_avg_allowed,
    o.outpatient_avg_allowed,
    (i.inpatient_avg_allowed + o.outpatient_avg_allowed) AS combined_avg_allowed
  FROM inpatient  i
  JOIN outpatient o USING (npi)
  JOIN `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014` p USING (npi)
  GROUP BY
    i.npi,
    i.inpatient_avg_allowed,
    o.outpatient_avg_allowed
)
SELECT
  npi,
  last_name,
  first_name,
  inpatient_avg_allowed,
  outpatient_avg_allowed,
  combined_avg_allowed
FROM combined
ORDER BY combined_avg_allowed DESC
LIMIT 1;