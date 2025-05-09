/* ----------------------------------------------------------
   Highest-spend provider (2011-2015) and its yearly averages
   ---------------------------------------------------------- */
WITH inpatient_all AS (   /* every DRG row, all 5 years */
    SELECT "provider_id",
           ("average_medicare_payments" * "total_discharges") AS cost,
           2011 AS yr
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
    UNION ALL
    SELECT "provider_id",
           ("average_medicare_payments" * "total_discharges"),
           2012
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
    UNION ALL
    SELECT "provider_id",
           ("average_medicare_payments" * "total_discharges"),
           2013
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
    UNION ALL
    SELECT "provider_id",
           ("average_medicare_payments" * "total_discharges"),
           2014
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    UNION ALL
    SELECT "provider_id",
           ("average_medicare_payments" * "total_discharges"),
           2015
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
),
/* identify the provider with the greatest 2011-2015 inpatient spend */
top_provider AS (
    SELECT "provider_id"
    FROM   inpatient_all
    GROUP  BY "provider_id"
    ORDER  BY SUM(cost) DESC NULLS LAST
    LIMIT  1
),
/* yearly average inpatient cost for that provider */
yearly_inpatient AS (
    SELECT yr,
           AVG(cost) AS avg_inpatient_cost
    FROM   inpatient_all
    WHERE  "provider_id" = (SELECT "provider_id" FROM top_provider)
    GROUP  BY yr
),
/* build one big outpatient table (all five years) */
outpatient_all AS (
    SELECT "provider_id",
           ("average_total_payments" * "outpatient_services") AS cost,
           2011 AS yr
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011
    UNION ALL
    SELECT "provider_id",
           ("average_total_payments" * "outpatient_services"),
           2012
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012
    UNION ALL
    SELECT "provider_id",
           ("average_total_payments" * "outpatient_services"),
           2013
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013
    UNION ALL
    SELECT "provider_id",
           ("average_total_payments" * "outpatient_services"),
           2014
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    UNION ALL
    SELECT "provider_id",
           ("average_total_payments" * "outpatient_services"),
           2015
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015
),
/* yearly average outpatient cost for that provider */
yearly_outpatient AS (
    SELECT yr,
           AVG(cost) AS avg_outpatient_cost
    FROM   outpatient_all
    WHERE  "provider_id" = (SELECT "provider_id" FROM top_provider)
    GROUP  BY yr
)
/* final result: inpatient & outpatient averages side-by-side */
SELECT
    i.yr                         AS "calendar_year",
    i.avg_inpatient_cost         AS "avg_inpatient_cost",
    o.avg_outpatient_cost        AS "avg_outpatient_cost"
FROM   yearly_inpatient  i
JOIN   yearly_outpatient o
  ON   i.yr = o.yr
ORDER  BY "calendar_year";