/*  Yearly average inpatient- and outpatient-cost profile for the single provider
    with the highest cumulative inpatient Medicare cost (2011-2015)            */

WITH /*-----------------------------------------------------------------------*
     * 1.  Gather every inpatient row for 2011-2015 and tag the calendar year  *
     *-----------------------------------------------------------------------*/
INPATIENT_UNION AS (
    SELECT "provider_id",
           "provider_name",
           "average_medicare_payments" AS "avg_pay",
           "total_discharges"          AS "disch",
           '2011'                      AS "year"
      FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
    UNION ALL
    SELECT "provider_id","provider_name","average_medicare_payments","total_discharges",'2012'
      FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
    UNION ALL
    SELECT "provider_id","provider_name","average_medicare_payments","total_discharges",'2013'
      FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
    UNION ALL
    SELECT "provider_id","provider_name","average_medicare_payments","total_discharges",'2014'
      FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
    UNION ALL
    SELECT "provider_id","provider_name","average_medicare_payments","total_discharges",'2015'
      FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
),

/*-----------------------------------------------------------------------*
 * 2.  Identify the single provider with the largest 5-year inpatient    *
 *     Medicare cost (Σ average_medicare_payments × total_discharges)    *
 *-----------------------------------------------------------------------*/
TOP_PROVIDER AS (
    SELECT "provider_id",
           "provider_name"
      FROM (
            SELECT "provider_id",
                   "provider_name",
                   SUM("avg_pay" * "disch") AS "total_inpatient_cost"
              FROM INPATIENT_UNION
             GROUP BY "provider_id","provider_name"
           )
     ORDER BY "total_inpatient_cost" DESC NULLS LAST
     LIMIT 1
),

/*-----------------------------------------------------------------------*
 * 3.  Year-level average inpatient cost for that provider               *
 *-----------------------------------------------------------------------*/
INPATIENT_YEARLY AS (
    SELECT iu."year",
           AVG(iu."avg_pay" * iu."disch") AS "avg_inpatient_cost"
      FROM INPATIENT_UNION  iu
      JOIN TOP_PROVIDER     tp
        ON iu."provider_id" = tp."provider_id"
     GROUP BY iu."year"
),

/*-----------------------------------------------------------------------*
 * 4.  Gather every outpatient row for 2011-2015 (with calendar year)    *
 *-----------------------------------------------------------------------*/
OUTPATIENT_UNION AS (
    SELECT "provider_id",
           "provider_name",
           "average_total_payments" AS "avg_pay",
           "outpatient_services"    AS "svcs",
           '2011'                   AS "year"
      FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2011"
    UNION ALL
    SELECT "provider_id","provider_name","average_total_payments","outpatient_services",'2012'
      FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2012"
    UNION ALL
    SELECT "provider_id","provider_name","average_total_payments","outpatient_services",'2013'
      FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2013"
    UNION ALL
    SELECT "provider_id","provider_name","average_total_payments","outpatient_services",'2014'
      FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2014"
    UNION ALL
    SELECT "provider_id","provider_name","average_total_payments","outpatient_services",'2015'
      FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2015"
),

/*-----------------------------------------------------------------------*
 * 5.  Year-level average outpatient cost for that same provider         *
 *-----------------------------------------------------------------------*/
OUTPATIENT_YEARLY AS (
    SELECT ou."year",
           AVG(ou."avg_pay" * ou."svcs") AS "avg_outpatient_cost"
      FROM OUTPATIENT_UNION ou
      JOIN TOP_PROVIDER    tp
        ON ou."provider_id" = tp."provider_id"
     GROUP BY ou."year"
)

/*------------------------------------------------------------------------*
 * 6.  Combine inpatient & outpatient yearly averages (2011-2015)         *
 *------------------------------------------------------------------------*/
SELECT iy."year"                                                   AS "year",
       iy."avg_inpatient_cost"                                      AS "avg_inpatient_cost",
       oy."avg_outpatient_cost"                                     AS "avg_outpatient_cost"
  FROM INPATIENT_YEARLY iy
  LEFT JOIN OUTPATIENT_YEARLY oy
    ON iy."year" = oy."year"
 ORDER BY iy."year";