WITH
/* --- 1.  GROSS INCOME INFLOW (annual IRS inflow AGI) ----------------------- */
gross_income AS (
    SELECT
        "DATE",
        SUM("VALUE")                                  AS "TOTAL_INFLOW_AGI"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE "GEO_ID"      = 'geoId/C38060'                                              -- Phoenix‑Mesa‑Scottsdale, AZ Metro
      AND "VARIABLE"    ILIKE 'Inflow_Returns_%adjusted_gross_income_from_Year_2%'    -- inflow AGI variables
      AND "DATE" IN ('2022-12-31','2023-12-31')                                       -- use 12‑31 values to bracket CY‑2023
    GROUP BY "DATE"
),

/* --- 2.  SEASONALLY‑ADJUSTED PURCHASE‑ONLY HPI (monthly FHFA) --------------- */
hpi_sa_purchase AS (
    SELECT
        "DATE",
        "VALUE"                                     AS "HPI_VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"   = 'geoId/C38060'                                  -- Phoenix‑Mesa‑Scottsdale, AZ Metro
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA' -- SA purchase‑only index
      AND "DATE" IN ('2023-01-31','2023-12-31')                         -- month‑end values bracketing 2023
)

/* --- 3.  RETURN PERCENTAGE CHANGES ---------------------------------------- */
SELECT
    'Gross Income Inflow (AGI) – % Change 2023'      AS "METRIC",
    ROUND(
        (
            MAX(CASE WHEN "DATE" = '2023-12-31' THEN "TOTAL_INFLOW_AGI" END) -
            MAX(CASE WHEN "DATE" = '2022-12-31' THEN "TOTAL_INFLOW_AGI" END)
        )
        /
        NULLIF(MAX(CASE WHEN "DATE" = '2022-12-31' THEN "TOTAL_INFLOW_AGI" END),0)
        * 100
    ,4)                                              AS "PERCENT_CHANGE"
FROM gross_income

UNION ALL

SELECT
    'FHFA SA Purchase‑Only HPI – % Change 2023'      AS "METRIC",
    ROUND(
        (
            MAX(CASE WHEN "DATE" = '2023-12-31' THEN "HPI_VALUE" END) -
            MAX(CASE WHEN "DATE" = '2023-01-31' THEN "HPI_VALUE" END)
        )
        /
        NULLIF(MAX(CASE WHEN "DATE" = '2023-01-31' THEN "HPI_VALUE" END),0)
        * 100
    ,4)                                              AS "PERCENT_CHANGE"
FROM hpi_sa_purchase;