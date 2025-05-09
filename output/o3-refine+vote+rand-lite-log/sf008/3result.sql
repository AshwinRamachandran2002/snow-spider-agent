/*--------------------------------------------------------------------
  % Change in (1) Gross Income Inflow and (2) Seasonally–Adjusted,
  Purchase‑Only FHFA HPI for the Phoenix–Mesa–Scottsdale, AZ Metro
  Area (CBSA geoId/C38060) between 1‑Jan‑2023 and 31‑Dec‑2023
--------------------------------------------------------------------*/
WITH
/* ----------  FHFA House‑Price Index (monthly, SA, purchase‑only) */
hpi_2023 AS (
    SELECT  "VALUE", "DATE"
    FROM    "US_REAL_ESTATE"."CYBERSYN"."FHFA_HOUSE_PRICE_TIMESERIES"
    WHERE   "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND   "GEO_ID"   = 'geoId/C38060'
      AND   "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
),
hpi_stats AS (
    SELECT
        /* first value in 2023 (≈ Jan‑2023) */  
        (SELECT "VALUE" FROM hpi_2023 ORDER BY "DATE" ASC  LIMIT 1)  AS start_value,
        /* last value in 2023 (≈ Dec‑2023)  */
        (SELECT "VALUE" FROM hpi_2023 ORDER BY "DATE" DESC LIMIT 1)  AS end_value
),

/* ----------  Identify variable code for gross‑income inflow (AGI) */
irs_var AS (
    SELECT  "VARIABLE"
    FROM    "US_REAL_ESTATE"."CYBERSYN"."IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES"
    WHERE   "RETURN_GROUP"   = 'Inflow Returns'
      AND   "INCOME_BRACKET" = 'All AGI classes'
      AND   "AGE_GROUP"      = 'All Ages'
      AND   "VARIABLE_NAME"  ILIKE '%adjusted gross income from Year 2%'
      LIMIT 1                          -- unique variable expected
),

/* ----------  Gross‑income inflow values for 2023 */
agi_2023 AS (
    SELECT  t."VALUE", t."DATE"
    FROM    "US_REAL_ESTATE"."CYBERSYN"."IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES" t
    JOIN    irs_var v
      ON    t."VARIABLE" = v."VARIABLE"
    WHERE   t."GEO_ID" = 'geoId/C38060'
      AND   t."DATE"  BETWEEN '2023-01-01' AND '2023-12-31'
),
agi_stats AS (
    SELECT
        (SELECT "VALUE" FROM agi_2023 ORDER BY "DATE" ASC  LIMIT 1) AS start_value,
        (SELECT "VALUE" FROM agi_2023 ORDER BY "DATE" DESC LIMIT 1) AS end_value
)

/* ----------  Assemble results & calculate % change */
SELECT
    'Gross Income Inflow (USD)'                                        AS "METRIC",
    g.start_value                                                      AS "VALUE_2023_01_01",
    g.end_value                                                        AS "VALUE_2023_12_31",
    ROUND( (g.end_value - g.start_value) / NULLIF(g.start_value,0)
           * 100 , 4)                                                  AS "PCT_CHANGE_2023"
FROM agi_stats g

UNION ALL

SELECT
    'FHFA Purchase‑Only HPI (SA, Index)'                               AS "METRIC",
    h.start_value                                                      AS "VALUE_2023_01_01",
    h.end_value                                                        AS "VALUE_2023_12_31",
    ROUND( (h.end_value - h.start_value) / NULLIF(h.start_value,0)
           * 100 , 4)                                                  AS "PCT_CHANGE_2023"
FROM hpi_stats h;