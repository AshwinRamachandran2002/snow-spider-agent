WITH agi AS (
    SELECT
        MAX(CASE WHEN "DATE" = '2022-12-31' THEN "VALUE" END) AS value_2022,
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS value_2023
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE "GEO_ID" = 'geoId/C38060'                                                         -- Phoenix‑Mesa‑Scottsdale, AZ Metro Area
      AND "VARIABLE" ILIKE 'Inflow_Returns_%adjusted_gross_income_from_Year_2,_all_ages,_All_AGI_classes'
      AND "DATE" IN ('2022-12-31','2023-12-31')
), hpi AS (
    SELECT
        MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) AS value_jan,
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS value_dec
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID" = 'geoId/C38060'                                                         -- Phoenix‑Mesa‑Scottsdale, AZ Metro Area
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'                      -- Seasonally‑adjusted purchase‑only HPI
      AND "DATE" IN ('2023-01-31','2023-12-31')
)
SELECT
    ROUND(100 * (agi.value_2023 - agi.value_2022) / agi.value_2022, 4) AS "AGI_INFLOW_PCT_CHANGE_2023",
    ROUND(100 * (hpi.value_dec - hpi.value_jan) / hpi.value_jan, 4)   AS "HPI_PCT_CHANGE_2023"
FROM agi, hpi;