/* ---------------------------------------------------------
   % change (2022-12-31 ➜ 2023-12-31) in

   1) Gross-income INFLOW (adjusted-gross-income, all ages,
      all-AGI-classes) for the counties that make-up the
      Phoenix-Mesa-Scottsdale (CBSA = geoId/C38060).

   2) Seasonally–adjusted purchase-only FHFA HPI for the same
      CBSA – first vs. last monthly reading inside CY-2023.
   ---------------------------------------------------------*/
WITH
-- ----------------------------------------------
-- all counties contained in the Phoenix CBSA
-- ----------------------------------------------
cbsa_counties AS (
    SELECT DISTINCT "GEO_ID"
    FROM US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE "RELATED_GEO_ID"   = 'geoId/C38060'      -- Phoenix-Mesa-Scottsdale CBSA
      AND "LEVEL"            = 'County'
      AND "RELATIONSHIP_TYPE"= 'Overlaps'
),

-- ----------------------------------------------
-- gross-income inflow, county-level … sum to CBSA
-- (IRS migration, Year-2 AGI, all ages & AGI classes)
-- ----------------------------------------------
agi_cbsa AS (
    SELECT
        "DATE",
        SUM("VALUE")                AS "AGI_VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE "GEO_ID" IN (SELECT "GEO_ID" FROM cbsa_counties)
      AND "VARIABLE"      ILIKE 'Inflow%adjusted%gross%income%Year_2%'
      AND "VARIABLE_NAME" ILIKE '%All AGI classes%'
      AND "DATE" IN ('2022-12-31','2023-12-31')
    GROUP BY "DATE"
),
agi_edge AS (
    SELECT
        MAX(CASE WHEN "DATE" = '2022-12-31' THEN "AGI_VALUE" END) AS "AGI_2022",
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN "AGI_VALUE" END) AS "AGI_2023"
    FROM agi_cbsa
),

-- ----------------------------------------------
-- FHFA HPI – seasonally-adjusted, purchase-only,
-- monthly series for the CBSA
-- ----------------------------------------------
hpi_monthly AS (
    SELECT
        "DATE",
        CAST("VALUE" AS FLOAT)       AS "HPI_VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"  = 'geoId/C38060'
      AND "VARIABLE" ILIKE '%purchase-only_monthly_SA'
      AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
),
hpi_edge AS (
    SELECT
        (SELECT "HPI_VALUE" FROM hpi_monthly ORDER BY "DATE"  ASC  LIMIT 1) AS "HPI_START_2023",
        (SELECT "HPI_VALUE" FROM hpi_monthly ORDER BY "DATE"  DESC LIMIT 1) AS "HPI_END_2023"
)

-- ----------------------------------------------
-- final %-change outputs
-- ----------------------------------------------
SELECT
    /* Gross-income inflow: 2022-12-31 ➜ 2023-12-31 */
    ( "AGI_2023" - "AGI_2022" ) / "AGI_2022" * 100  AS "PCT_CHANGE_GROSS_INCOME_INFLOW",

    /* FHFA Purchase-Only HPI: Jan-2023 first obs ➜ Dec-2023 last obs */
    ( "HPI_END_2023" - "HPI_START_2023" ) / "HPI_START_2023" * 100
                                                AS "PCT_CHANGE_PURCHASE_ONLY_HPI"
FROM agi_edge
CROSS JOIN hpi_edge;