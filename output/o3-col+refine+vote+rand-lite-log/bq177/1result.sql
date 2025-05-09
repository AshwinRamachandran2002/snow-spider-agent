/*------------------------------------------------------------
  1) Identify the provider with the largest TOTAL inpatient cost
     ( Σ total_discharges * average_medicare_payments ) for 2011-2015.
  2) For that provider return, for each calendar year 2011-2015,
        • average inpatient cost
        • average outpatient cost
------------------------------------------------------------*/
WITH
/* --------- Inpatient records (2011, 2013-2015) --------- */
inp_raw AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)                         AS yr,
    provider_id,
    total_discharges * average_medicare_payments         AS record_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_20*`
  WHERE _TABLE_SUFFIX IN ('2011','2013','2014','2015')
),

/* ---------  Provider whose total inpatient cost is highest --------- */
top_provider AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name
  FROM (
    SELECT
      provider_id,
      provider_name,
      total_discharges * average_medicare_payments AS record_cost
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_20*`
    WHERE _TABLE_SUFFIX IN ('2011','2013','2014','2015')
  )
  GROUP BY provider_id
  ORDER BY SUM(record_cost) DESC
  LIMIT 1
),

/* ---------  Year-by-year average inpatient cost  --------- */
inp_yearly AS (
  SELECT
    yr,
    AVG(record_cost) AS avg_inpatient_cost
  FROM inp_raw
  JOIN top_provider USING (provider_id)
  GROUP BY yr
),

/* ---------  Outpatient records (2011-2015)  --------- */
out_raw AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)                       AS yr,
    provider_id,
    outpatient_services * average_total_payments       AS record_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_20*`
  WHERE _TABLE_SUFFIX IN ('2011','2012','2013','2014','2015')
),

/* ---------  Year-by-year average outpatient cost --------- */
out_yearly AS (
  SELECT
    yr,
    AVG(record_cost) AS avg_outpatient_cost
  FROM out_raw
  JOIN top_provider USING (provider_id)
  GROUP BY yr
),

/* ---------  List of all calendar years  --------- */
yrs AS (
  SELECT yr
  FROM UNNEST([2011,2012,2013,2014,2015]) AS yr
)

/* ----------------  Final result  ---------------- */
SELECT
  yrs.yr,
  inp_yearly.avg_inpatient_cost,
  out_yearly.avg_outpatient_cost
FROM yrs
LEFT JOIN inp_yearly  USING (yr)
LEFT JOIN out_yearly USING (yr)
ORDER BY yr;