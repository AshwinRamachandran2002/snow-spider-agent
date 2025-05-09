/*  ---------------------------------------------------------------
    Percentage change (2023) in
      1) Gross-income inflow (IRS AGI) and
      2) Seasonally-adjusted purchase-only FHFA HPI
    for the Phoenix-Mesa-Scottsdale, AZ Metro Area (geoId/C38060)
    ---------------------------------------------------------------- */
WITH county_list AS (   -- counties contained in the CBSA
    SELECT DISTINCT "GEO_ID"
    FROM   US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE  "RELATED_GEO_ID" = 'geoId/C38060'
      AND  "LEVEL"          = 'County'
      AND  "RELATIONSHIP_TYPE" = 'Contains'
),

/* --- gross-income inflow summed across all CBSA counties -------- */
agi_by_date AS (
    SELECT
           t."DATE",
           SUM(t."VALUE") AS "AGI_INFLOW_USD"
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES t
    JOIN   county_list c
           ON t."GEO_ID" = c."GEO_ID"
    WHERE  t."VARIABLE" = 'Inflow_Returns_–_adjusted_gross_income_from_Year_1,_all_ages,_All_AGI_classes'
      AND  t."DATE" IN ('2022-12-31','2023-12-31')            -- start & end of 2023
    GROUP  BY t."DATE"
),

/* --- seasonally-adjusted purchase-only FHFA HPI ----------------- */
hpi_by_date AS (
    SELECT
           "DATE",
           "VALUE" AS "HPI_INDEX"
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE  "GEO_ID"   = 'geoId/C38060'
      AND  "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_quarterly_SA'
      AND  "DATE" IN ('2022-12-31','2023-12-31')
)

/* --------- calculate 2023 percentage changes ------------------- */
SELECT
       'Gross Income Inflow' AS "MEASURE",
       ( MAX(CASE WHEN "DATE" = '2023-12-31' THEN "AGI_INFLOW_USD" END)
       - MAX(CASE WHEN "DATE" = '2022-12-31' THEN "AGI_INFLOW_USD" END) )
       / NULLIF( MAX(CASE WHEN "DATE" = '2022-12-31' THEN "AGI_INFLOW_USD" END), 0)
       * 100          AS "PERCENT_CHANGE_2023"
FROM   agi_by_date

UNION ALL

SELECT
       'FHFA Purchase-Only HPI (SA)' AS "MEASURE",
       ( MAX(CASE WHEN "DATE" = '2023-12-31' THEN "HPI_INDEX" END)
       - MAX(CASE WHEN "DATE" = '2022-12-31' THEN "HPI_INDEX" END) )
       / NULLIF( MAX(CASE WHEN "DATE" = '2022-12-31' THEN "HPI_INDEX" END), 0)
       * 100          AS "PERCENT_CHANGE_2023"
FROM   hpi_by_date;