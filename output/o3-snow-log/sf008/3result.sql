/*  Percentage-change in 2023 gross-income inflow and seasonally–adjusted,
    purchase-only FHFA House-Price Index (HPI) for the Phoenix-Mesa-Scottsdale, AZ CBSA
    (geoId/C38060).                                              */

WITH 

/* --- 1) identify the required variable codes ------------------------------------ */
gross_var AS (            -- total adjusted-gross-income inflow, all ages, all AGI classes
    SELECT "VARIABLE"
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES
    WHERE  "VARIABLE_NAME" ILIKE
           'Inflow%adjusted%gross%income%Year_1,%all ages,%All AGI classes'
    LIMIT  1
),
hpi_var AS (              -- seasonally–adjusted, purchase-only HPI (monthly series)
    SELECT "VARIABLE"
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_ATTRIBUTES
    WHERE  "INDEX_TYPE"          =  'purchase-only'
      AND  "SEASONALLY_ADJUSTED" =  TRUE
      AND  "FREQUENCY"           =  'MONTHLY'
    LIMIT  1
),

/* --- 2) pull start-of-year and end-of-year values for each series --------------- */
gross AS (
    SELECT
        MAX( CASE WHEN "DATE" = '2022-12-31' THEN "VALUE" END ) AS start_val,   -- proxy for 1-Jan-2023
        MAX( CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END ) AS end_val
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES  g
    JOIN   gross_var v  ON g."VARIABLE" = v."VARIABLE"
    WHERE  g."GEO_ID" = 'geoId/C38060'
),
hpi AS (
    SELECT
        MAX( CASE WHEN "DATE" = '2023-01-31' THEN CAST("VALUE" AS FLOAT) END ) AS start_val,
        MAX( CASE WHEN "DATE" = '2023-12-31' THEN CAST("VALUE" AS FLOAT) END ) AS end_val
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES  h
    JOIN   hpi_var v   ON h."VARIABLE" = v."VARIABLE"
    WHERE  h."GEO_ID" = 'geoId/C38060'
)

/* --- 3) calculate percentage changes ------------------------------------------- */
SELECT
    ROUND( (gross.end_val - gross.start_val) / gross.start_val * 100 , 4)
        AS "PCT_CHANGE_GROSS_INCOME_INFLOW_2023",
    ROUND( (hpi.end_val   - hpi.start_val)   / hpi.start_val   * 100 , 4)
        AS "PCT_CHANGE_HPI_SA_PURCHASE_ONLY_2023"
FROM   gross, hpi;