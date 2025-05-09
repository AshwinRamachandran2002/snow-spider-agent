/*--------------------------------------------------------------------
  % change in (1) gross income inflow and (2) seasonally–adjusted,
  purchase‑only HPI for the Phoenix‑Mesa‑Scottsdale, AZ metro (CBSA
  GEO_ID = geoId/C38060) during calendar‑year 2023
--------------------------------------------------------------------*/
WITH

/* --------  FHFA House‑Price Index (monthly, SA, purchase‑only) ---- */
hpi_raw AS (
    SELECT  "DATE",
            "VALUE"
    FROM    US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE   "GEO_ID"  = 'geoId/C38060'
      AND   "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND   "DATE" IN ( '2023-01-31',   -- start of period
                        '2023-12-31')   -- end   of period
),
hpi AS (
    SELECT  MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) AS hpi_start,
            MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS hpi_end
    FROM    hpi_raw
),

/* --------  IRS gross income inflow (annual, USD) ------------------ */
agi_raw AS (
    SELECT  t."DATE",
            t."VALUE"
    FROM    US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES       t
    JOIN    US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES  a
           ON t."VARIABLE" = a."VARIABLE"
    WHERE   t."GEO_ID"        = 'geoId/C38060'
      AND   a."RETURN_GROUP"  = 'Inflow Returns'
      AND   a."AGE_GROUP"     = 'All Ages'
      AND   a."INCOME_BRACKET"= 'All AGI classes'
      AND   a."UNIT"          = 'USD'
      AND   t."DATE" IN ('2022-12-31',   -- start‑of‑year proxy
                         '2023-12-31')   -- end‑of‑year
),
agi AS (
    SELECT  MAX(CASE WHEN "DATE" = '2022-12-31' THEN "VALUE" END) AS agi_start,
            MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS agi_end
    FROM    agi_raw
)

/* -------------------------  Final output  ------------------------- */
SELECT
    ROUND( (agi_end - agi_start) / agi_start * 100, 4 ) AS "GROSS_INCOME_INFLOW_PCT_CHANGE_2023",
    ROUND( (hpi_end - hpi_start) / hpi_start * 100, 4 ) AS "HPI_PCT_CHANGE_2023"
FROM    agi
CROSS JOIN hpi;