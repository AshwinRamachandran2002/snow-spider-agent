/*  -----------------------------------------------------------------------
    % change during calendar‑year 2023 in
      1) gross inflow Adjusted‑Gross‑Income (all ages, all AGI classes)
      2) seasonally‑adjusted purchase‑only FHFA House‑Price Index
         for the Phoenix‑Mesa‑Scottsdale, AZ Metro (CBSA 38060)
    ----------------------------------------------------------------------- */

WITH agi_var AS (   -- pick the single variable that represents AGI inflow (USD)
    SELECT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES
    WHERE "RETURN_GROUP"   = 'Inflow Returns'
      AND "UNIT"           = 'USD'
      AND "AGE_GROUP"      = 'All Ages'
      AND "INCOME_BRACKET" = 'All AGI classes'
      AND LOWER("VARIABLE") LIKE '%adjusted_gross_income_from_year_2%'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "VARIABLE") = 1
),

agi_vals AS (        -- annual series: use 2022‑12‑31 as proxy for 1‑Jan‑2023
    SELECT
        MAX(CASE WHEN "DATE" = '2022-12-31' THEN "VALUE" END) AS "AGI_START",
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS "AGI_END"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE "GEO_ID"   = 'geoId/C38060'
      AND "VARIABLE" = (SELECT "VARIABLE" FROM agi_var)
),

hpi_vals AS (        -- monthly HPI (seasonally‑adjusted, purchase‑only)
    SELECT
        MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) AS "HPI_START",
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS "HPI_END"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"   = 'geoId/C38060'
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
)

SELECT
    ROUND( (("AGI_END" - "AGI_START") / "AGI_START") * 100 , 4) AS "PCT_CHANGE_AGI_INFLOW_2023",
    ROUND( (("HPI_END" - "HPI_START") / "HPI_START") * 100 , 4) AS "PCT_CHANGE_HPI_SA_PURCHASE_ONLY_2023"
FROM agi_vals
CROSS JOIN hpi_vals;