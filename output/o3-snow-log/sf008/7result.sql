/*-------------------------------------------------------------------------------------------------
  % CHANGE (2023)  •  PHOENIX-MESA-SCOTTSDALE, AZ CBSA   (geoId/C38060)

  1)  Gross-income inflow
      – IRS Migration by Characteristic Timeseries
      – Variable: “Inflow … adjusted gross income … Year 2 … All AGI classes, All Ages”
      – Annual values → compare 2022-12-31  vs  2023-12-31
      – Sum over every county that belongs to the CBSA

  2)  Seasonally–adjusted purchase-only FHFA HPI
      – Variable: FHFA_HPI_traditional_purchase-only_monthly_SA
      – Monthly values → compare 2023-01-31  vs  2023-12-31
-------------------------------------------------------------------------------------------------*/
WITH
/* ----  counties inside the Phoenix CBSA  ---- */
phoenix_counties AS (
    SELECT DISTINCT
           /* county GEO_ID, whichever side of the relationship it appears on */
           COALESCE(
               CASE WHEN "LEVEL" = 'County'        THEN "GEO_ID"          END,
               CASE WHEN "RELATED_LEVEL" = 'County' THEN "RELATED_GEO_ID" END
           )  AS county_geo_id
    FROM US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE (
              "GEO_ID"        = 'geoId/C38060' AND "RELATED_LEVEL" = 'County' AND "RELATIONSHIP_TYPE" = 'Contains'
          )
       OR (
              "RELATED_GEO_ID" = 'geoId/C38060' AND "LEVEL"        = 'County' AND "RELATIONSHIP_TYPE" = 'Overlaps'
          )
),

/* ----  grab the exact IRS variable code we need  ---- */
irs_income_variable AS (
    SELECT DISTINCT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES
    WHERE "VARIABLE_NAME" ILIKE 'Inflow%adjusted gross income%'
      AND "VARIABLE_NAME" ILIKE '%Year 2%'          -- Year-2 AGI (most recent-year inflow)
      AND "VARIABLE_NAME" ILIKE '%All AGI classes%'
      AND "AGE_GROUP"      =  'All Ages'
),

/* ----  income values for 2022-12-31 & 2023-12-31 summed across counties  ---- */
income_annual AS (
    SELECT
        t."DATE",
        SUM(t."VALUE") AS income_value
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES t
    JOIN irs_income_variable v   ON t."VARIABLE" = v."VARIABLE"
    JOIN phoenix_counties   pc   ON t."GEO_ID"   = pc.county_geo_id
    WHERE t."DATE" IN ('2022-12-31','2023-12-31')
    GROUP BY t."DATE"
),

/* ----  % change in gross-income inflow  ---- */
income_pct_change AS (
    SELECT
        100.0 * ( MAX(CASE WHEN "DATE"='2023-12-31' THEN income_value END)
                - MAX(CASE WHEN "DATE"='2022-12-31' THEN income_value END) )
        / NULLIF( MAX(CASE WHEN "DATE"='2022-12-31' THEN income_value END), 0 )
        AS pct_change_income_2023
    FROM income_annual
),

/* ----  HPI values for 2023-01-31 & 2023-12-31  ---- */
hpi_monthly AS (
    SELECT
        "DATE",
        "VALUE" AS hpi_value
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"   = 'geoId/C38060'
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND "DATE" IN ('2023-01-31','2023-12-31')
),

/* ----  % change in seasonally-adjusted purchase-only HPI  ---- */
hpi_pct_change AS (
    SELECT
        100.0 * ( MAX(CASE WHEN "DATE"='2023-12-31' THEN hpi_value END)
                - MAX(CASE WHEN "DATE"='2023-01-31' THEN hpi_value END) )
        / NULLIF( MAX(CASE WHEN "DATE"='2023-01-31' THEN hpi_value END), 0 )
        AS pct_change_hpi_2023
    FROM hpi_monthly
)

/* ----  final output  ---- */
SELECT 'Gross Income Inflow % Change (2023)'                       AS "METRIC",
       pct_change_income_2023                                      AS "PERCENT_CHANGE"
FROM   income_pct_change

UNION ALL

SELECT 'Seasonally-Adjusted Purchase-Only HPI % Change (2023)'     AS "METRIC",
       pct_change_hpi_2023                                         AS "PERCENT_CHANGE"
FROM   hpi_pct_change;