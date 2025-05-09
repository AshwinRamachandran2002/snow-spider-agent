-- Percentage-change (2023) in
--   1) Gross-income inflow (total AGI) and
--   2) Seasonally–adjusted, purchase-only FHFA HPI
-- for the Phoenix-Mesa-Scottsdale, AZ Metro Area  (GEO_ID = 'geoId/C38060')

WITH phoenix_counties AS (   -- all counties contained in the metro area
    SELECT "RELATED_GEO_ID"                AS "COUNTY_GEO_ID"
    FROM   US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE  "GEO_ID"        = 'geoId/C38060'      -- Phoenix-Mesa-Scottsdale CBSA
      AND  "RELATED_LEVEL" = 'County'
      AND  "RELATIONSHIP_TYPE" = 'Contains'
),

/* ----------  Gross-income inflow (IRS migration)  ---------- */
gross_income AS (
    SELECT 
           "DATE",
           SUM("VALUE")            AS "VAL"
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES t
           JOIN phoenix_counties c
                ON t."GEO_ID" = c."COUNTY_GEO_ID"
    WHERE  t."VARIABLE" = 'Inflow_Returns_–_adjusted_gross_income_from_Year_2,_all_ages,_All_AGI_classes'
      AND  t."DATE" IN ('2022-12-31','2023-12-31')   -- start & end of 2023 period
    GROUP  BY "DATE"
),
gross_income_pct AS (
    SELECT 100.0 * ( MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VAL" END)
                   - MAX(CASE WHEN "DATE" = '2022-12-31' THEN "VAL" END) )
                   / NULLIF( MAX(CASE WHEN "DATE" = '2022-12-31' THEN "VAL" END) , 0 )
                   AS "PCT_CHANGE_GROSS_INCOME_2023"
    FROM   gross_income
),

/* ----------  FHFA HPI (seasonally-adjusted, purchase-only)  ---------- */
hpi AS (
    SELECT "DATE", "VALUE"
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE  "GEO_ID"   = 'geoId/C38060'
      AND  "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND  "DATE" IN ('2023-01-31','2023-12-31')      -- first & last month of 2023
),
hpi_pct AS (
    SELECT 100.0 * ( MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END)
                   - MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) )
                   / NULLIF( MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) , 0 )
                   AS "PCT_CHANGE_HPI_2023"
    FROM   hpi
)

/* ----------  Final output  ---------- */
SELECT g."PCT_CHANGE_GROSS_INCOME_2023",
       h."PCT_CHANGE_HPI_2023"
FROM   gross_income_pct g
CROSS  JOIN hpi_pct     h;