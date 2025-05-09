/*---------------------------------------------------------------------
  Percentage change (Jan‑to‑Dec 2023) for
  1) Gross income inflow (IRS adjusted‑gross‑income inflow)
  2) Seasonally‑adjusted purchase‑only FHFA HPI
  Phoenix–Mesa–Scottsdale, AZ Metro Area  (CBSA GEO_ID = geoId/C38060)
---------------------------------------------------------------------*/
WITH phoenix_counties AS (   -- counties contained in the Phoenix MSA
    SELECT DISTINCT "RELATED_GEO_ID"  AS county_geo_id
    FROM US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE "GEO_ID" = 'geoId/C38060'
      AND "RELATIONSHIP_TYPE" = 'Contains'
      AND "RELATED_LEVEL" = 'County'
),
income_vars AS (            -- variable(s) that capture total AGI inflow
    SELECT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES
    WHERE "RETURN_GROUP"   = 'Inflow Returns'
      AND "UNIT"           = 'USD'
      AND "INCOME_BRACKET" = 'All AGI classes'
      AND "AGE_GROUP"      = 'All Ages'
),
income_23 AS (              -- gross AGI inflow at start & end of 2023
    SELECT
        SUM(CASE WHEN "DATE" = '2022-12-31' THEN "VALUE" END) AS gross_start,
        SUM(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS gross_end
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE "VARIABLE" IN (SELECT "VARIABLE" FROM income_vars)
      AND "GEO_ID"  IN (SELECT county_geo_id FROM phoenix_counties)
),
hpi_vars AS (               -- seasonally‑adjusted purchase‑only HPI id
    SELECT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_ATTRIBUTES
    WHERE "INDEX_TYPE" = 'purchase-only'
      AND "FREQUENCY"  = 'MONTHLY'
      AND "SEASONALLY_ADJUSTED" = TRUE
),
hpi_23 AS (                 -- HPI level at Jan‑31‑2023 & Dec‑31‑2023
    SELECT
        MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) AS hpi_start,
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS hpi_end
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "VARIABLE" IN (SELECT "VARIABLE" FROM hpi_vars)
      AND "GEO_ID"   = 'geoId/C38060'
)
SELECT
    /* percentage change in gross AGI inflow */
    (income_23.gross_end  - income_23.gross_start)
      / NULLIF(income_23.gross_start,0) * 100  AS "GROSS_INCOME_INFLOW_PCT_CHANGE",
    /* percentage change in seasonally‑adjusted purchase‑only HPI */
    (hpi_23.hpi_end      - hpi_23.hpi_start)
      / NULLIF(hpi_23.hpi_start,0)    * 100  AS "HPI_PCT_CHANGE"
FROM income_23
CROSS JOIN hpi_23;