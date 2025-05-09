/*  % change in 2023 gross-income inflow & seasonally-adjusted purchase-only HPI
    for the Phoenix–Mesa–Scottsdale, AZ Metro Area (CBSA geoId/C38060)          */

WITH county_list AS (   -- counties contained in the Phoenix CBSA
    SELECT DISTINCT "RELATED_GEO_ID" AS "COUNTY_GEO_ID"
    FROM   US_REAL_ESTATE.CYBERSYN."GEOGRAPHY_RELATIONSHIPS"
    WHERE  "GEO_ID"            = 'geoId/C38060'
      AND  "RELATED_LEVEL"     = 'County'
      AND  "RELATIONSHIP_TYPE" = 'Contains'
),

/* -------- 1)  Gross AGI inflow (IRS migration – adjusted gross income) ------ */
agi_raw AS (
    SELECT
           "DATE",
           SUM("VALUE") AS "TOTAL_AGI"
    FROM   US_REAL_ESTATE.CYBERSYN."IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES"
    WHERE  "GEO_ID" IN (SELECT "COUNTY_GEO_ID" FROM county_list)
      AND  "VARIABLE" = 'Inflow_Returns_–_adjusted_gross_income_from_Year_2,_all_ages,_All_AGI_classes'
      AND  "DATE" IN ('2022-12-31', '2023-12-31')
    GROUP BY "DATE"
),
agi_change AS (
    SELECT
        (
          MAX(CASE WHEN "DATE" = '2023-12-31' THEN "TOTAL_AGI" END) -
          MAX(CASE WHEN "DATE" = '2022-12-31' THEN "TOTAL_AGI" END)
        )
        / NULLIF(MAX(CASE WHEN "DATE" = '2022-12-31' THEN "TOTAL_AGI" END), 0)
        * 100 AS "PCT_CHANGE"
    FROM agi_raw
),

/* --- 2)  FHFA purchase-only, seasonally-adjusted House Price Index (HPI) ---- */
hpi_raw AS (
    SELECT
           "DATE",
           CAST("VALUE" AS FLOAT) AS "HPI_VAL"
    FROM   US_REAL_ESTATE.CYBERSYN."FHFA_HOUSE_PRICE_TIMESERIES"
    WHERE  "GEO_ID"   = 'geoId/C38060'
      AND  "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND  "DATE" IN ('2023-01-31', '2023-12-31')
),
hpi_change AS (
    SELECT
        (
          MAX(CASE WHEN "DATE" = '2023-12-31' THEN "HPI_VAL" END) -
          MAX(CASE WHEN "DATE" = '2023-01-31'  THEN "HPI_VAL" END)
        )
        / NULLIF(MAX(CASE WHEN "DATE" = '2023-01-31' THEN "HPI_VAL" END), 0)
        * 100 AS "PCT_CHANGE"
    FROM hpi_raw
)

/* ------------------------------  Final output ------------------------------- */
SELECT 'Gross AGI Inflow % Change (2023 vs 2022)'                         AS "MEASURE",
       "PCT_CHANGE"
FROM   agi_change

UNION ALL

SELECT 'Seasonally-Adjusted Purchase-Only HPI % Change (Jan-Dec 2023)',
       "PCT_CHANGE"
FROM   hpi_change;