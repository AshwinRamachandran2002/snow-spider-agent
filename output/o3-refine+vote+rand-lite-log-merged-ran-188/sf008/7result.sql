/*--------------------------------------------------------------
  Goal: 2023 percentage-change (Jan-31 → Dec-31) for
        1) FHFA purchase-only, seasonally-adjusted HPI
        2) Total inflow AGI (Year-2) summed across all counties
           that make up the Phoenix–Mesa–Scottsdale, AZ CBSA
----------------------------------------------------------------*/

WITH county_list AS (   -- every county fully contained in the CBSA
    SELECT DISTINCT
           r."RELATED_GEO_ID" AS "COUNTY_GEO_ID"
    FROM   "US_REAL_ESTATE"."CYBERSYN"."GEOGRAPHY_RELATIONSHIPS" r
    WHERE  r."GEO_ID"           = 'geoId/C38060'   -- Phoenix–Mesa–Scottsdale, AZ Metro
      AND  r."RELATIONSHIP_TYPE"= 'Contains'
      AND  r."RELATED_LEVEL"    = 'County'
),
agi_variable AS (       -- grab the exact IRS variable code we need
    SELECT  DISTINCT
            a."VARIABLE"
    FROM    "US_REAL_ESTATE"."CYBERSYN"."IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES" a
    WHERE   a."RETURN_GROUP"   = 'Inflow Returns'
      AND   a."UNIT"           = 'USD'
      AND   a."AGE_GROUP"      = 'All Ages'
      AND   a."INCOME_BRACKET" = 'All AGI classes'
      AND   a."VARIABLE"       ILIKE 'Inflow_Returns%Year_2%'      -- use Year-2 AGI
    LIMIT 1                     -- only one code matches these filters
),
agi_data AS (           -- aggregate county inflow AGI for 2022 & 2023
    SELECT
        t."DATE",
        SUM(t."VALUE") AS "AGI_VALUE"
    FROM   "US_REAL_ESTATE"."CYBERSYN"."IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES" t
    JOIN   county_list  c  ON t."GEO_ID"  = c."COUNTY_GEO_ID"
    JOIN   agi_variable v  ON t."VARIABLE"= v."VARIABLE"
    WHERE  t."DATE" IN ('2022-12-31','2023-12-31')
    GROUP  BY t."DATE"
),
agi_pct AS (            -- 2023 % change for AGI inflow
    SELECT
        ROUND(
            100.0 *
            (
              MAX(CASE WHEN "DATE"='2023-12-31' THEN "AGI_VALUE" END) -
              MAX(CASE WHEN "DATE"='2022-12-31' THEN "AGI_VALUE" END)
            ) /
            MAX(CASE WHEN "DATE"='2022-12-31' THEN "AGI_VALUE" END)
        , 2)  AS "AGI_INFLOW_PCT_CHANGE_2023"
    FROM agi_data
),
hpi_data AS (           -- HPI values for Jan-31 & Dec-31 2023
    SELECT
        t."DATE",
        t."VALUE"
    FROM   "US_REAL_ESTATE"."CYBERSYN"."FHFA_HOUSE_PRICE_TIMESERIES" t
    WHERE  t."GEO_ID"   = 'geoId/C38060'
      AND  t."VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND  t."DATE" IN ('2023-01-31','2023-12-31')
),
hpi_pct AS (            -- 2023 % change for HPI
    SELECT
        ROUND(
            100.0 *
            (
              MAX(CASE WHEN "DATE"='2023-12-31' THEN "VALUE" END) -
              MAX(CASE WHEN "DATE"='2023-01-31' THEN "VALUE" END)
            ) /
            MAX(CASE WHEN "DATE"='2023-01-31' THEN "VALUE" END)
        , 2)  AS "HPI_PCT_CHANGE_2023"
    FROM hpi_data
)

SELECT
       h."HPI_PCT_CHANGE_2023"   AS "HPI_%_CHANGE_2023",
       a."AGI_INFLOW_PCT_CHANGE_2023" AS "AGI_INFLOW_%_CHANGE_2023"
FROM   hpi_pct h
CROSS  JOIN agi_pct a;