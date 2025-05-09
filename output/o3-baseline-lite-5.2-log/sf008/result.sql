/*------------------------------------------------------------
  % change in (1) gross AGI inflow and (2) seasonally–adjusted
  purchase‑only FHFA HPI for the Phoenix‑Mesa‑Scottsdale, AZ
  Metro Area during calendar‑year 2023
------------------------------------------------------------*/
WITH

/* 1.  variable that represents TOTAL adjusted‑gross‑income INFLOWS */
inflow_var AS (
    SELECT "VARIABLE"
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES
    WHERE  "RETURN_GROUP"   = 'Inflow Returns'
      AND  "INCOME_BRACKET" = 'All AGI classes'
      AND  "AGE_GROUP"      = 'All Ages'
      AND  "UNIT"           = 'USD'
),

/* 2.  counties that make up the Phoenix‑Mesa‑Scottsdale, AZ MSA (CBSA 38060) */
phoenix_counties AS (
    SELECT DISTINCT "GEO_ID"
    FROM   US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE  "RELATED_GEO_ID"   = 'geoId/C38060'          -- Phoenix‑Mesa‑Scottsdale, AZ CBSA
      AND  "RELATIONSHIP_TYPE" = 'Overlaps'
      AND  "LEVEL"             = 'County'
),

/* 3.  aggregate gross AGI inflow for those counties, year‑end 2022 vs. 2023 */
gross_inflow_by_date AS (
    SELECT  "DATE",
            SUM("VALUE") AS total_agi_inflow
    FROM    US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE   "VARIABLE"  IN (SELECT "VARIABLE" FROM inflow_var)
      AND   "GEO_ID"    IN (SELECT "GEO_ID" FROM phoenix_counties)
      AND   "DATE"      IN ('2022-12-31', '2023-12-31')
    GROUP BY "DATE"
),

/* 4.  % change in gross AGI inflow during 2023 */
gross_inflow_pct_change AS (
    SELECT  100.0 *
            ( MAX(CASE WHEN "DATE" = '2023-12-31' THEN total_agi_inflow END)
            - MAX(CASE WHEN "DATE" = '2022-12-31' THEN total_agi_inflow END) )
            / NULLIF( MAX(CASE WHEN "DATE" = '2022-12-31' THEN total_agi_inflow END) , 0 )
            AS pct_change_gross_agi_inflow_2023
    FROM    gross_inflow_by_date
),

/* 5.  FHFA seasonally‑adjusted purchase‑only HPI (monthly) for CBSA 38060 */
hpi_values AS (
    SELECT  "DATE",
            "VALUE"
    FROM    US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE   "GEO_ID"   = 'geoId/C38060'
      AND   "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND   "DATE" IN ('2023-01-31', '2023-12-31')
),

/* 6.  % change in that HPI between Jan‑31‑2023 and Dec‑31‑2023 */
hpi_pct_change AS (
    SELECT  100.0 *
            ( MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END)
            - MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) )
            / NULLIF( MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) , 0 )
            AS pct_change_purchase_only_hpi_sa_2023
    FROM    hpi_values
)

/* 7.  final result */
SELECT  pct_change_gross_agi_inflow_2023  AS "PCT_CHANGE_GROSS_INCOME_INFLOW_2023",
        pct_change_purchase_only_hpi_sa_2023 AS "PCT_CHANGE_PURCHASE_ONLY_HPI_SA_2023"
FROM    gross_inflow_pct_change
CROSS JOIN hpi_pct_change;