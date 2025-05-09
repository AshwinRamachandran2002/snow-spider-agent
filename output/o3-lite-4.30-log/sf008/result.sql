WITH metro AS (   -- Phoenix–Mesa–Scottsdale, AZ MSA
    SELECT 'geoId/C38060' AS "METRO_GEO_ID"
),
/* ---------------- all counties contained in the metro ---------------- */
counties AS (
    SELECT DISTINCT "RELATED_GEO_ID" AS "COUNTY_GEO_ID"
    FROM "US_REAL_ESTATE"."CYBERSYN"."GEOGRAPHY_RELATIONSHIPS" gr
    JOIN metro m
      ON gr."GEO_ID" = m."METRO_GEO_ID"
    WHERE gr."RELATIONSHIP_TYPE" = 'Contains'
      AND gr."RELATED_LEVEL"    = 'County'
),
/* ---------------- total AGI inflow into those counties ---------------- */
agi_totals AS (
    SELECT  "DATE",
            SUM("VALUE") AS "TOTAL_AGI_INFLOW_USD"
    FROM    "US_REAL_ESTATE"."CYBERSYN"."IRS_ORIGIN_DESTINATION_MIGRATION_TIMESERIES"
    WHERE   "TO_GEO_ID" IN (SELECT "COUNTY_GEO_ID" FROM counties)
      AND   "VARIABLE_NAME" = 'Adjusted Gross Income'
      AND   "DATE" IN ('2022-12-31','2023-12-31')          -- flows for 2022 & 2023 tax‑years
    GROUP BY "DATE"
),
agi_pct AS (
    SELECT  (MAX(CASE WHEN "DATE" = '2023-12-31' THEN "TOTAL_AGI_INFLOW_USD" END) -
             MAX(CASE WHEN "DATE" = '2022-12-31' THEN "TOTAL_AGI_INFLOW_USD" END))
            /
             MAX(CASE WHEN "DATE" = '2022-12-31' THEN "TOTAL_AGI_INFLOW_USD" END) * 100
            AS "PCT_CHANGE"
    FROM   agi_totals
),
/* ---------------- FHFA purchase‑only (monthly, SA) HPI ---------------- */
hpi_vals AS (
    SELECT  "DATE",
            "VALUE"
    FROM    "US_REAL_ESTATE"."CYBERSYN"."FHFA_HOUSE_PRICE_TIMESERIES"
    WHERE   "GEO_ID"  = 'geoId/C38060'
      AND   "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND   "DATE" IN ('2023-01-31','2023-12-31')
),
hpi_pct AS (
    SELECT  (MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) -
             MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END))
            /
             MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) * 100
            AS "PCT_CHANGE"
    FROM   hpi_vals
)
/* ---------------- final two‑row CSV output ---------------- */
SELECT 'gross_income_inflow_pct_change'  AS metric,
       ROUND((SELECT "PCT_CHANGE" FROM agi_pct), 4) AS percentage_change
UNION ALL
SELECT 'hpi_purchase_only_sa_pct_change' AS metric,
       ROUND((SELECT "PCT_CHANGE" FROM hpi_pct), 4) AS percentage_change;