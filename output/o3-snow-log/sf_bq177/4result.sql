/*---------------------------------------------------------------
  1)  Build one union for ALL inpatient rows (2011-2015)
      and another union for ALL outpatient rows (2011-2015).
  2)  Identify the single provider that has the greatest
      TOTAL inpatient Medicare cost over 2011-2015.
  3)  For that provider calculate, for every calendar year
      (2011-2015):
           • average inpatient cost  = AVG(average_medicare_payments
                                            * total_discharges)
           • average outpatient cost = AVG(average_total_payments
                                            * outpatient_services)
  4)  Return the two yearly averages side-by-side.
----------------------------------------------------------------*/
WITH inp_all AS (      -- 5 years of INPATIENT files
    SELECT 2011 AS yr,
           "provider_id",
           "provider_name",
           ("average_medicare_payments" * "total_discharges")      AS cost
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
    UNION ALL
    SELECT 2012, "provider_id", "provider_name",
           ("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
    UNION ALL
    SELECT 2013, "provider_id", "provider_name",
           ("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
    UNION ALL
    SELECT 2014, "provider_id", "provider_name",
           ("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    UNION ALL
    SELECT 2015, "provider_id", "provider_name",
           ("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
),
/* -- provider that spends the MOST on inpatient care (2011-2015) */
top_provider AS (
    SELECT  "provider_id",
            MAX("provider_name")     AS provider_name    -- just to keep one name
    FROM    inp_all
    GROUP BY "provider_id"
    ORDER BY SUM(cost) DESC NULLS LAST
    LIMIT 1
),
/* -- Yearly average INPATIENT cost for that provider */
inpatient_yearly AS (
    SELECT  ia.yr,
            AVG(ia.cost)             AS avg_inpatient_cost
    FROM    inp_all        AS ia
    JOIN    top_provider   AS tp
           ON ia."provider_id" = tp."provider_id"
    GROUP BY ia.yr
),
/* -- build ALL OUTPATIENT rows (2011-2015) */
out_all AS (
    SELECT 2011 AS yr,
           "provider_id",
           ("average_total_payments" * "outpatient_services")        AS cost
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011
    UNION ALL
    SELECT 2012, "provider_id",
           ("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012
    UNION ALL
    SELECT 2013, "provider_id",
           ("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013
    UNION ALL
    SELECT 2014, "provider_id",
           ("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    UNION ALL
    SELECT 2015, "provider_id",
           ("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015
),
/* -- Yearly average OUTPATIENT cost for that provider */
outpatient_yearly AS (
    SELECT  oa.yr,
            AVG(oa.cost)            AS avg_outpatient_cost
    FROM    out_all        AS oa
    JOIN    top_provider   AS tp
           ON oa."provider_id" = tp."provider_id"
    GROUP BY oa.yr
)
/*----------------------------------------------------------------
   Final result – yearly averages for 2011-2015
  --------------------------------------------------------------*/
SELECT  yrs.yr                                        AS "year",
        ROUND(iy.avg_inpatient_cost , 4)              AS "average_inpatient_cost",
        ROUND(oy.avg_outpatient_cost, 4)              AS "average_outpatient_cost"
FROM   (           -- helper set with the five calendar years
        SELECT 2011 AS yr UNION ALL
        SELECT 2012       UNION ALL
        SELECT 2013       UNION ALL
        SELECT 2014       UNION ALL
        SELECT 2015
      ) yrs
LEFT  JOIN inpatient_yearly  AS iy  ON yrs.yr = iy.yr
LEFT  JOIN outpatient_yearly AS oy  ON yrs.yr = oy.yr
ORDER BY yrs.yr;