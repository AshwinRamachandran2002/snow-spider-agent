/*-----------------------------------------------------------
  % change (2023) for two separate series – both tied to the 
  Phoenix-Mesa-Scottsdale, AZ Metro Area (CBSA GEO_ID = geoId/C38060)

  1) Adjusted-gross-income inflow (IRS migration – all ages, all AGI classes)
     – annual values exist on 12-31 for each year, so use
       2022-12-31 as the start-of-2023 reference and
       2023-12-31 as the end-of-2023 reference.

  2) FHFA purchase-only, seasonally-adjusted HPI (monthly)
     – use 2023-01-31 vs. 2023-12-31.

  The query returns the 2023 percent change for each metric.
-----------------------------------------------------------*/
WITH agi_inflow AS (   -- IRS migration – grab the two annual points
    SELECT
        "VALUE"       AS agi_value,
        "DATE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE "GEO_ID" = 'geoId/C38060'  -- Phoenix-Mesa-Scottsdale, AZ CBSA
      AND "VARIABLE_NAME" ILIKE
          'Inflow%adjusted%gross%income%Year 2,%all%ages,%All%AGI%classes%'
      AND "DATE" IN ('2022-12-31', '2023-12-31')
),
agi_change AS (
    SELECT
        MAX(CASE WHEN "DATE" = '2022-12-31' THEN agi_value END) AS agi_start,
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN agi_value END) AS agi_end
    FROM agi_inflow
),
hpi_series AS (        -- FHFA HPI – grab Jan & Dec 2023
    SELECT
        CAST("VALUE" AS FLOAT) AS hpi_value,
        "DATE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"  = 'geoId/C38060'                       -- same CBSA
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND "DATE"    IN ('2023-01-31','2023-12-31')
),
hpi_change AS (
    SELECT
        MAX(CASE WHEN "DATE" = '2023-01-31' THEN hpi_value END) AS hpi_start,
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN hpi_value END) AS hpi_end
    FROM hpi_series
)
SELECT
    /* percent change in AGI inflow, 2023 */
    ROUND(
        (agi_change.agi_end - agi_change.agi_start)
        / agi_change.agi_start * 100
    ,4) AS "PCT_CHANGE_AGI_INFLOW_2023",
    
    /* percent change in seasonally-adjusted purchase-only HPI, 2023 */
    ROUND(
        (hpi_change.hpi_end - hpi_change.hpi_start)
        / hpi_change.hpi_start * 100
    ,4) AS "PCT_CHANGE_HPI_SA_PURCHASE_ONLY_2023"
FROM agi_change
CROSS JOIN hpi_change;