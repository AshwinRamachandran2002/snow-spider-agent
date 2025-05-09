/*  Step 1 – identify the single provider whose 2011-2015 inpatient cost is the highest          */
/*          (  Σ average_medicare_payments × total_discharges  across all five years )           */
/*  Step 2 – for that provider, calculate PER-YEAR                                                 */
/*          a) average inpatient cost  = AVG(average_medicare_payments × total_discharges)       */
/*          b) average outpatient cost = AVG(average_total_payments  × outpatient_services)      */

WITH top_provider AS (

    SELECT
        ip_all."provider_id"
    FROM (
             /* ---------- 2011 ---------- */
             SELECT
                 "provider_id",
                 "average_medicare_payments" * "total_discharges" AS line_cost
             FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
         UNION ALL
             /* ---------- 2012 ---------- */
             SELECT
                 "provider_id",
                 "average_medicare_payments" * "total_discharges"
             FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
         UNION ALL
             /* ---------- 2013 ---------- */
             SELECT
                 "provider_id",
                 "average_medicare_payments" * "total_discharges"
             FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
         UNION ALL
             /* ---------- 2014 ---------- */
             SELECT
                 "provider_id",
                 "average_medicare_payments" * "total_discharges"
             FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
         UNION ALL
             /* ---------- 2015 ---------- */
             SELECT
                 "provider_id",
                 "average_medicare_payments" * "total_discharges"
             FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
         ) ip_all
    GROUP BY ip_all."provider_id"
    ORDER BY SUM(ip_all.line_cost) DESC NULLS LAST
    LIMIT 1
),

/* ------------------------  per-year average inpatient cost  ------------------------ */
inpatient_yearly AS (
    /* 2011 */
    SELECT
        2011                                           AS "year",
        AVG("average_medicare_payments" * "total_discharges") AS "avg_inpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011  ic11
    JOIN top_provider tp ON ic11."provider_id" = tp."provider_id"

    UNION ALL
    /* 2012 */
    SELECT
        2012,
        AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012  ic12
    JOIN top_provider tp ON ic12."provider_id" = tp."provider_id"

    UNION ALL
    /* 2013 */
    SELECT
        2013,
        AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013  ic13
    JOIN top_provider tp ON ic13."provider_id" = tp."provider_id"

    UNION ALL
    /* 2014 */
    SELECT
        2014,
        AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014  ic14
    JOIN top_provider tp ON ic14."provider_id" = tp."provider_id"

    UNION ALL
    /* 2015 */
    SELECT
        2015,
        AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015  ic15
    JOIN top_provider tp ON ic15."provider_id" = tp."provider_id"
),

/* ------------------------  per-year average outpatient cost  ----------------------- */
outpatient_yearly AS (
    /* 2011 */
    SELECT
        2011                                           AS "year",
        AVG("average_total_payments" * "outpatient_services") AS "avg_outpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011 op11
    JOIN top_provider tp ON op11."provider_id" = tp."provider_id"

    UNION ALL
    /* 2012 */
    SELECT
        2012,
        AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012 op12
    JOIN top_provider tp ON op12."provider_id" = tp."provider_id"

    UNION ALL
    /* 2013 */
    SELECT
        2013,
        AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013 op13
    JOIN top_provider tp ON op13."provider_id" = tp."provider_id"

    UNION ALL
    /* 2014 */
    SELECT
        2014,
        AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014 op14
    JOIN top_provider tp ON op14."provider_id" = tp."provider_id"

    UNION ALL
    /* 2015 */
    SELECT
        2015,
        AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015 op15
    JOIN top_provider tp ON op15."provider_id" = tp."provider_id"
)

/* ------------------------------  final result  ------------------------------------ */
SELECT
    ip."year",
    ip."avg_inpatient_cost",
    op."avg_outpatient_cost"
FROM inpatient_yearly  ip
JOIN outpatient_yearly op
      ON ip."year" = op."year"
ORDER BY ip."year";