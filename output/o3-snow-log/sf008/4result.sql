/*--------------------------------------------------------------------
  % change in 2023 gross-income inflow and SA purchase-only HPI
  for the Phoenix-Mesa-Scottsdale, AZ Metro Area (GEO_ID = geoId/C38060)
--------------------------------------------------------------------*/
WITH county_list AS (  -- all counties contained in the Phoenix CBSA
    SELECT DISTINCT "RELATED_GEO_ID"  AS county_geo_id
    FROM   US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE  "GEO_ID"          = 'geoId/C38060'          -- Phoenix-Mesa-Scottsdale, AZ
      AND  "RELATIONSHIP_TYPE" = 'Contains'
      AND  "RELATED_LEVEL"     = 'County'
),  
income AS (            -- aggregate inflow AGI for 2022 & 2023
    SELECT
        t."DATE",
        SUM(t."VALUE") AS total_inflow_income
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES t
    JOIN   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES a
           ON t."VARIABLE" = a."VARIABLE"
    WHERE  t."GEO_ID" IN (SELECT county_geo_id FROM county_list)
      AND  a."RETURN_GROUP"   = 'Inflow Returns'
      AND  a."UNIT"           = 'USD'
      AND  a."AGE_GROUP"      = 'All Ages'
      AND  a."INCOME_BRACKET" = 'All AGI classes'
      AND  t."DATE" IN ('2022-12-31','2023-12-31')
    GROUP BY t."DATE"
),  
income_change AS (      -- percent change 2022->2023
    SELECT
        (MAX(CASE WHEN "DATE"='2023-12-31' THEN total_inflow_income END) -
         MAX(CASE WHEN "DATE"='2022-12-31' THEN total_inflow_income END))
        / NULLIF(MAX(CASE WHEN "DATE"='2022-12-31' THEN total_inflow_income END),0) * 100
        AS income_pct_change
    FROM income
),  
hpi AS (                -- SA purchase-only HPI (quarterly) first & last 2023 obs
    SELECT
        "DATE",
        "VALUE" AS hpi_value
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE  "GEO_ID"   = 'geoId/C38060'
      AND  "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_quarterly_SA'
      AND  "DATE" IN ('2023-03-31','2023-12-31')   -- first & last 2023 quarters
),  
hpi_change AS (         -- percent change within 2023
    SELECT
        (MAX(CASE WHEN "DATE"='2023-12-31' THEN hpi_value END) -
         MAX(CASE WHEN "DATE"='2023-03-31' THEN hpi_value END))
        / NULLIF(MAX(CASE WHEN "DATE"='2023-03-31' THEN hpi_value END),0) * 100
        AS hpi_pct_change
    FROM hpi
)
SELECT
    income_change.income_pct_change  AS "GROSS_INFLOW_AGI_PCT_CHANGE_2023",
    hpi_change.hpi_pct_change        AS "SA_PURCHASE_ONLY_HPI_PCT_CHANGE_2023"
FROM income_change
CROSS JOIN hpi_change;