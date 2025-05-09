/*  Yearly average inpatient and outpatient cost for the provider that
    has the highest TOTAL inpatient Medicare cost during 2011‑2015      */

WITH
/* ---------------------------------------------------
   1.  Inpatient costs for every provider, 2011‑2015
   --------------------------------------------------- */
inpatient_all AS (
    SELECT 2011 AS yr, provider_id,
           average_medicare_payments * total_discharges AS cost
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

/* ---------------------------------------------------------
   2.  Identify provider with greatest TOTAL inpatient cost
   --------------------------------------------------------- */
top_provider AS (
    SELECT provider_id
    FROM (
        SELECT provider_id,
               SUM(cost) AS total_inpatient_cost
        FROM inpatient_all
        GROUP BY provider_id
        ORDER BY total_inpatient_cost DESC
        LIMIT 1
    )
),

/* -------------------------------------------------
   3.  Yearly AVERAGE inpatient cost for top provider
   ------------------------------------------------- */
inpatient_yearly AS (
    SELECT
        yr,
        AVG(cost) AS avg_inpatient_cost
    FROM inpatient_all
    WHERE provider_id = (SELECT provider_id FROM top_provider)
    GROUP BY yr
),

/* -----------------------------------------------
   4.  Outpatient costs for every provider 2011‑15
   ----------------------------------------------- */
outpatient_all AS (
    SELECT 2011 AS yr, provider_id,
           average_total_payments * outpatient_services AS cost
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

/* --------------------------------------------------
   5.  Yearly AVERAGE outpatient cost for top provider
   -------------------------------------------------- */
outpatient_yearly AS (
    SELECT
        yr,
        AVG(cost) AS avg_outpatient_cost
    FROM outpatient_all
    WHERE provider_id = (SELECT provider_id FROM top_provider)
    GROUP BY yr
)

/* --------------------------------------------------
   6.  Combine inpatient & outpatient yearly averages
   -------------------------------------------------- */
SELECT
    (SELECT provider_id FROM top_provider) AS provider_id,
    yr AS year,
    i.avg_inpatient_cost,
    o.avg_outpatient_cost
FROM UNNEST([2011,2012,2013,2014,2015]) AS yr
LEFT JOIN inpatient_yearly  AS i USING (yr)
LEFT JOIN outpatient_yearly AS o USING (yr)
ORDER BY year;