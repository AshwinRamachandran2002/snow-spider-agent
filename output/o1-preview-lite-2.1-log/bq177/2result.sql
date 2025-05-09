SELECT
  inpatient.year AS Year,
  ROUND((inpatient.total_inpatient_revenue / inpatient.total_inpatient_discharges), 4) AS Average_Inpatient_Revenue_per_Case,
  ROUND((outpatient.total_outpatient_revenue / outpatient.total_outpatient_services), 4) AS Average_Outpatient_Revenue_per_Case
FROM
  (
    SELECT
      _TABLE_SUFFIX AS year,
      SUM(total_discharges * average_total_payments) AS total_inpatient_revenue,
      SUM(total_discharges) AS total_inpatient_discharges
    FROM
      `bigquery-public-data.cms_medicare.inpatient_charges_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '2011' AND '2015' AND
      provider_id = '330101'
    GROUP BY
      year
  ) AS inpatient
JOIN
  (
    SELECT
      _TABLE_SUFFIX AS year,
      SUM(outpatient_services * average_total_payments) AS total_outpatient_revenue,
      SUM(outpatient_services) AS total_outpatient_services
    FROM
      `bigquery-public-data.cms_medicare.outpatient_charges_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '2011' AND '2015' AND
      provider_id = '330101'
    GROUP BY
      year
  ) AS outpatient
ON
  inpatient.year = outpatient.year
ORDER BY
  Year;