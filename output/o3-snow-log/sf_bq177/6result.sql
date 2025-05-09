/*------------------------------------------------------------
  1.  Gather every inpatient & outpatient record for 2011-2015,
      computing the row-level cost we need in each case.
------------------------------------------------------------*/
WITH   union_inpatient  AS (
         SELECT '2011'          AS "year",
                "provider_id",
                "provider_name",
                "total_discharges" * "average_medicare_payments" :: FLOAT  AS "row_inp_cost"
         FROM   CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
         UNION ALL
         SELECT '2012', "provider_id", "provider_name",
                "total_discharges" * "average_medicare_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
         UNION ALL
         SELECT '2013', "provider_id", "provider_name",
                "total_discharges" * "average_medicare_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
         UNION ALL
         SELECT '2014', "provider_id", "provider_name",
                "total_discharges" * "average_medicare_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
         UNION ALL
         SELECT '2015', "provider_id", "provider_name",
                "total_discharges" * "average_medicare_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
       ),

       union_outpatient AS (
         SELECT '2011'          AS "year",
                "provider_id",
                "outpatient_services" * "average_total_payments" :: FLOAT  AS "row_outp_cost"
         FROM   CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011
         UNION ALL
         SELECT '2012', "provider_id",
                "outpatient_services" * "average_total_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012
         UNION ALL
         SELECT '2013', "provider_id",
                "outpatient_services" * "average_total_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013
         UNION ALL
         SELECT '2014', "provider_id",
                "outpatient_services" * "average_total_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
         UNION ALL
         SELECT '2015', "provider_id",
                "outpatient_services" * "average_total_payments" :: FLOAT
         FROM   CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015
       ),

/*------------------------------------------------------------
  2.  Identify the provider whose TOTAL inpatient cost (2011-2015)
      is the highest.
------------------------------------------------------------*/
       top_provider AS (
         SELECT  "provider_id"
         FROM    union_inpatient
         GROUP BY "provider_id"
         ORDER BY SUM("row_inp_cost") DESC NULLS LAST
         LIMIT 1
       ),

/*------------------------------------------------------------
  3.  Year-by-year average inpatient & outpatient costs
      for that single provider.
------------------------------------------------------------*/
       yearly_inpatient  AS (
         SELECT  ui."year",
                 AVG(ui."row_inp_cost") AS "avg_inpatient_cost"
         FROM    union_inpatient ui
         WHERE   ui."provider_id" = (SELECT "provider_id" FROM top_provider)
         GROUP BY ui."year"
       ),

       yearly_outpatient AS (
         SELECT  uo."year",
                 AVG(uo."row_outp_cost") AS "avg_outpatient_cost"
         FROM    union_outpatient uo
         WHERE   uo."provider_id" = (SELECT "provider_id" FROM top_provider)
         GROUP BY uo."year"
       )

/*------------------------------------------------------------
  4.  Final result: one row per calendar year (2011-2015) with
      the provider’s average inpatient & outpatient costs.
------------------------------------------------------------*/
SELECT        yi."year",
              yi."avg_inpatient_cost",
              yo."avg_outpatient_cost"
FROM          yearly_inpatient  yi
FULL  JOIN    yearly_outpatient yo
          ON  yi."year" = yo."year"
ORDER BY      yi."year";