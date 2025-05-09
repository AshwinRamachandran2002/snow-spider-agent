/*------------------------------------------------------------
  % change in
  1) Gross income inflow (IRS migration – adjusted gross income) and
  2) Seasonally–adjusted, purchase‑only FHFA HPI

  Geography  : Phoenix‑Mesa‑Scottsdale, AZ Metro Area (CBSA 38060 → geoId/C38060)
  Period     : Start‑of‑year vs. end‑of‑year 2023
               – Gross–income inflow values are published annually (value dated 12‑31)
                 → compare 2022‑12‑31 to 2023‑12‑31
               – HPI is monthly; compare 2023‑01‑31 to 2023‑12‑31
 ------------------------------------------------------------*/
WITH counties_in_cbsa AS (          -- every county wholly contained in the Phoenix CBSA
    SELECT DISTINCT "RELATED_GEO_ID" AS "COUNTY_GEO_ID"
    FROM US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE "GEO_ID"          = 'geoId/C38060'      -- Phoenix‑Mesa‑Scottsdale metro
      AND "RELATIONSHIP_TYPE" = 'Contains'
      AND "RELATED_LEVEL"     = 'County'
),
income_values AS (                 -- total AGI inflow for those counties
    SELECT
        irs."DATE",
        SUM(irs."VALUE")             AS "INCOME_VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES irs
    JOIN counties_in_cbsa c
      ON irs."GEO_ID" = c."COUNTY_GEO_ID"
    WHERE irs."VARIABLE" = 'Inflow_Returns_–_adjusted_gross_income_from_Year_2,_all_ages,_All_AGI_classes'
      AND irs."DATE" IN ('2022-12-31', '2023-12-31')
    GROUP BY irs."DATE"
),
income_change AS (                 -- % change 2022‑12‑31 ➜ 2023‑12‑31
    SELECT
        ( MAX(CASE WHEN "DATE"='2023-12-31' THEN "INCOME_VALUE" END)
        - MAX(CASE WHEN "DATE"='2022-12-31' THEN "INCOME_VALUE" END) )
        / NULLIF(MAX(CASE WHEN "DATE"='2022-12-31' THEN "INCOME_VALUE" END),0) * 100
        AS "GROSS_INCOME_INFLOW_PCT_CHANGE"
    FROM income_values
),
hpi_values AS (                    -- January & December 2023 seasonally‑adjusted purchase‑only HPI
    SELECT
        "DATE",
        CAST("VALUE" AS FLOAT) AS "HPI_VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"   = 'geoId/C38060'
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND "DATE" IN ('2023-01-31', '2023-12-31')
),
hpi_change AS (                    -- % change 2023‑01‑31 ➜ 2023‑12‑31
    SELECT
        ( MAX(CASE WHEN "DATE"='2023-12-31' THEN "HPI_VALUE" END)
        - MAX(CASE WHEN "DATE"='2023-01-31' THEN "HPI_VALUE" END) )
        / NULLIF(MAX(CASE WHEN "DATE"='2023-01-31' THEN "HPI_VALUE" END),0) * 100
        AS "HPI_PCT_CHANGE"
    FROM hpi_values
)
SELECT
    inc."GROSS_INCOME_INFLOW_PCT_CHANGE",
    hpi."HPI_PCT_CHANGE"
FROM income_change inc
CROSS JOIN hpi_change hpi;