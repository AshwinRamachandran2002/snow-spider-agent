/*------------------------------------------------------------
  % change 2023 vs. 2022 in
    1) In‑flow Adjusted‑Gross‑Income (AGI) to all counties that
       compose the Phoenix‑Mesa‑Scottsdale, AZ CBSA (geoId/C38060)
    2) Seasonally–adjusted, purchase‑only FHFA HPI for the same CBSA
-------------------------------------------------------------*/
WITH phoenix_counties AS (      -- counties fully contained in the CBSA
    SELECT DISTINCT
           "RELATED_GEO_ID"  AS "COUNTY_ID"
    FROM   US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE  "GEO_ID"           = 'geoId/C38060'           -- Phoenix‑Mesa‑Scottsdale, AZ
      AND  "RELATIONSHIP_TYPE"= 'Contains'
      AND  "RELATED_LEVEL"    = 'County'
),

/* ---------- 1)  AGI in‑flow (county‑to‑county IRS migration) ---------- */
agi_inflow AS (
    SELECT  "DATE",
            SUM("VALUE") AS "AGI_USD"
    FROM    US_REAL_ESTATE.CYBERSYN.IRS_ORIGIN_DESTINATION_MIGRATION_TIMESERIES
    WHERE   "TO_GEO_ID"     IN (SELECT "COUNTY_ID" FROM phoenix_counties)
      AND   "VARIABLE_NAME" = 'Adjusted Gross Income'
      AND   "DATE"          IN ('2022-12-31','2023-12-31')
    GROUP BY "DATE"
),
agi_pct AS (
    SELECT  100 * ( MAX(CASE WHEN "DATE"='2023-12-31' THEN "AGI_USD" END)
                  - MAX(CASE WHEN "DATE"='2022-12-31' THEN "AGI_USD" END) )
            /  MAX(CASE WHEN "DATE"='2022-12-31' THEN "AGI_USD" END)  AS "PCT_CHANGE"
    FROM    agi_inflow
),

/* ---------- 2)  FHFA purchase‑only, SA, monthly HPI ---------- */
hpi_start_end AS (
    SELECT  "DATE",
            "VALUE" AS "HPI_VAL"
    FROM    US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE   "GEO_ID"   = 'geoId/C38060'        -- Phoenix CBSA
      AND   "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND   "DATE" IN ('2023-01-31','2023-12-31')
),
hpi_pct AS (
    SELECT  100 * ( MAX(CASE WHEN "DATE"='2023-12-31' THEN "HPI_VAL" END)
                  - MAX(CASE WHEN "DATE"='2023-01-31' THEN "HPI_VAL" END) )
            /  MAX(CASE WHEN "DATE"='2023-01-31' THEN "HPI_VAL" END)  AS "PCT_CHANGE"
    FROM    hpi_start_end
)

/* ---------- Final output ---------- */
SELECT 'Gross Income Inflow (AGI)'      AS "METRIC",
       ROUND("PCT_CHANGE",4)            AS "PERCENT_CHANGE_2023"
FROM   agi_pct

UNION ALL

SELECT 'FHFA HPI Purchase‑Only SA'      AS "METRIC",
       ROUND("PCT_CHANGE",4)            AS "PERCENT_CHANGE_2023"
FROM   hpi_pct;