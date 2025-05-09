-- Year‑by‑year average inpatient and outpatient cost for the single provider
-- with the highest total inpatient Medicare cost (2011‑2015)

WITH
/* ------------------------------------------------------------------------ */
/* 1. Identify the provider with the largest 2011‑2015 TOTAL inpatient cost */
inpatient_all AS (
  SELECT 2011 AS yr, provider_id,
         average_medicare_payments * total_discharges AS line_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`

  UNION ALL
  SELECT 2012, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`

  UNION ALL
  SELECT 2013, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`

  UNION ALL
  SELECT 2014, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`

  UNION ALL
  SELECT 2015, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
),
top_provider AS (            -- only the provider with the largest summed cost
  SELECT provider_id
  FROM (
    SELECT provider_id, SUM(line_cost) AS total_inpatient_cost
    FROM inpatient_all
    GROUP BY provider_id
    ORDER BY total_inpatient_cost DESC
    LIMIT 1
  )
),

/* ------------------------------------------------------------------------ */
/* 2. Yearly AVERAGE inpatient cost for the top provider                    */
inpatient_yearly AS (
  SELECT
    ia.yr,
    AVG(ia.line_cost) AS avg_inpatient_cost
  FROM inpatient_all AS ia
  JOIN top_provider tp
    ON ia.provider_id = tp.provider_id
  GROUP BY ia.yr
),

/* ------------------------------------------------------------------------ */
/* 3. Yearly AVERAGE outpatient cost for the same provider                  */
outpatient_all AS (
  SELECT 2011 AS yr, provider_id,
         average_total_payments * outpatient_services AS line_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`

  UNION ALL
  SELECT 2012, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`

  UNION ALL
  SELECT 2013, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`

  UNION ALL
  SELECT 2014, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`

  UNION ALL
  SELECT 2015, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
),
outpatient_yearly AS (
  SELECT
    oa.yr,
    AVG(oa.line_cost) AS avg_outpatient_cost
  FROM outpatient_all AS oa
  JOIN top_provider tp
    ON oa.provider_id = tp.provider_id
  GROUP BY oa.yr
)

/* ------------------------------------------------------------------------ */
/* 4. Combine inpatient & outpatient results                                */
SELECT
  iy.yr AS calendar_year,
  iy.avg_inpatient_cost,
  oy.avg_outpatient_cost
FROM inpatient_yearly iy
FULL JOIN outpatient_yearly oy
  USING (yr)
ORDER BY calendar_year;