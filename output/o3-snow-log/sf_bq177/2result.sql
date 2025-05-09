/*-----------------------------------------------------------------------------
  1) Identify the provider whose TOTAL inpatient-Medicare cost during
     2011-2015 is the greatest   (cost = average_medicare_payments ×
     total_discharges, summed over all DRGs and all five files).

  2) For that single provider, return one row per calendar year (2011-2015)
     that shows
         – the average inpatient cost   = AVG(average_medicare_payments × total_discharges)
         – the average outpatient cost  = AVG(average_total_payments  × outpatient_services)
-----------------------------------------------------------------------------*/
WITH top_provider AS (         -- provider with the largest 5-year inpatient cost
    SELECT  "provider_id"
    FROM   (
            /* 2011-2015 inpatient files with their cost contribution            */
            SELECT "provider_id",
                   ("average_medicare_payments" * "total_discharges") AS cost
            FROM   CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
            UNION ALL
            SELECT "provider_id",
                   ("average_medicare_payments" * "total_discharges")
            FROM   CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
            UNION ALL
            SELECT "provider_id",
                   ("average_medicare_payments" * "total_discharges")
            FROM   CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
            UNION ALL
            SELECT "provider_id",
                   ("average_medicare_payments" * "total_discharges")
            FROM   CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
            UNION ALL
            SELECT "provider_id",
                   ("average_medicare_payments" * "total_discharges")
            FROM   CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
          ) t
    GROUP  BY "provider_id"
    ORDER  BY SUM(cost) DESC NULLS LAST
    LIMIT 1
),
/*------------------  yearly average INPATIENT cost --------------------------*/
yearly_inp AS (
    SELECT  2011 AS yr,
            AVG("average_medicare_payments" * "total_discharges") AS avg_inpatient_cost
    FROM    CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2012,
            AVG("average_medicare_payments" * "total_discharges")
    FROM    CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2013,
            AVG("average_medicare_payments" * "total_discharges")
    FROM    CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2014,
            AVG("average_medicare_payments" * "total_discharges")
    FROM    CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2015,
            AVG("average_medicare_payments" * "total_discharges")
    FROM    CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)
),
/*------------------  yearly average OUTPATIENT cost -------------------------*/
yearly_outp AS (
    SELECT  2011 AS yr,
            AVG("average_total_payments" * "outpatient_services") AS avg_outpatient_cost
    FROM    CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2011"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2012,
            AVG("average_total_payments" * "outpatient_services")
    FROM    CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2012"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2013,
            AVG("average_total_payments" * "outpatient_services")
    FROM    CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2013"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2014,
            AVG("average_total_payments" * "outpatient_services")
    FROM    CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2014"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)

    UNION ALL
    SELECT  2015,
            AVG("average_total_payments" * "outpatient_services")
    FROM    CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2015"
    WHERE   "provider_id" = (SELECT "provider_id" FROM top_provider)
)
/*------------------  final result ------------------------------------------*/
SELECT  (SELECT "provider_id" FROM top_provider)               AS provider_id,
        i.yr,
        i.avg_inpatient_cost,
        o.avg_outpatient_cost
FROM    yearly_inp i
JOIN    yearly_outp o
       ON i.yr = o.yr
ORDER BY i.yr;