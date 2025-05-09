/*--------------------------------------------------------------------
  % change in (1) gross-income inflow and (2) seasonally-adjusted
  purchase-only FHFA HPI for the Phoenix-Mesa-Scottsdale, AZ CBSA
  (geoId/C38060) during calendar-year 2023
--------------------------------------------------------------------*/
WITH
/*------------------------------------------------------------------*
 * 1)  TOTAL ADJUSTED-GROSS-INCOME  (INFLOW)                        *
 *------------------------------------------------------------------*/
agi_raw AS (   -- all inflow-AGI variables, all ages, all AGI classes
    SELECT
        "DATE",
        "VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE  "GEO_ID"        = 'geoId/C38060'               -- Phoenix CBSA
      AND  "VARIABLE_NAME" ILIKE '%Inflow%adjusted%gross%income%'
      AND  "VARIABLE_NAME" ILIKE '%All%AGI%classes%'
      AND  "DATE" IN ('2022-12-31','2023-12-31')          -- bracketing 2023
),
agi_tot AS (    -- sum across any Year-1 / Year-2 variants
    SELECT
        "DATE",
        SUM("VALUE") AS agi_val
    FROM   agi_raw
    GROUP  BY "DATE"
),
agi_change AS (
    SELECT
        MAX(CASE WHEN "DATE" = '2022-12-31' THEN agi_val END) AS agi_start,
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN agi_val END) AS agi_end
    FROM agi_tot
),
agi_pct AS (
    SELECT
        100.0 * (agi_end - agi_start) / agi_start AS agi_pct_change
    FROM agi_change
),

/*------------------------------------------------------------------*
 * 2)  FHFA PURCHASE-ONLY, SEASONALLY-ADJUSTED HOUSE-PRICE INDEX    *
 *------------------------------------------------------------------*/
hpi_raw AS (
    SELECT
        "DATE",
        "VALUE"::FLOAT AS hpi_val
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE  "GEO_ID"        = 'geoId/C38060'               -- Phoenix CBSA
      AND  "VARIABLE_NAME" ILIKE '%purchase-only%'
      AND  "VARIABLE_NAME" ILIKE '%Seasonally Adjusted%'
      AND  "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
),
hpi_edge AS (   -- first and last month-end observations in 2023
    SELECT
        MIN_BY(hpi_val, "DATE") AS hpi_start,   -- 2023-01-xx
        MAX_BY(hpi_val, "DATE") AS hpi_end      -- 2023-12-xx
    FROM hpi_raw
),
hpi_pct AS (
    SELECT
        100.0 * (hpi_end - hpi_start) / hpi_start AS hpi_pct_change
    FROM hpi_edge
)

/*------------------------------------------------------------------*
 * 3)  FINAL OUTPUT                                                *
 *------------------------------------------------------------------*/
SELECT
    agi_pct_change AS "AGI_INFLOW_PERCENT_CHANGE_2023",
    hpi_pct_change AS "FHFA_HPI_PERCENT_CHANGE_2023"
FROM agi_pct, hpi_pct;