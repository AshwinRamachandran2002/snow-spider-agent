/*---------------------------------------------------------------
  % change (2023) for
  1) Inflow of adjusted-gross-income (all ages, all AGI classes)
     – IRS migration data
  2) FHFA Purchase-Only House-Price Index (seasonally-adjusted)
     – Phoenix-Mesa-Scottsdale, AZ Metro Area (CBSA 38060)
----------------------------------------------------------------*/
WITH
/* ---------- helper : get GEO_ID for Phoenix-Mesa-Scottsdale CBSA ---------- */
phoenix AS (
    SELECT 'geoId/C38060'::TEXT AS "GEO_ID"   -- CBSA code 38060
),
/* ---------- IRS AGI INFLOW (annual values) ---------- */
agi_vals AS (
    SELECT
        t."VALUE",
        EXTRACT(YEAR FROM t."DATE")       AS "YEAR"
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES t
    JOIN   phoenix p
           ON t."GEO_ID" = p."GEO_ID"
    /* pick the exact variable via attributes table so accents don’t break */
    WHERE  t."VARIABLE" = (
              SELECT  a."VARIABLE"
              FROM    US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_ATTRIBUTES a
              WHERE   a."VARIABLE_NAME" ILIKE '%Inflow%adjusted gross income%Year 2%all ages%All AGI classes%'
                  AND a."UNIT" = 'USD'
              LIMIT 1
           )
      AND  t."DATE" IN ('2022-12-31','2023-12-31')      -- need both yrs for % change
),
agi_change AS (
    SELECT
        MAX(CASE WHEN "YEAR" = 2022 THEN "VALUE" END) AS "VAL_2022",
        MAX(CASE WHEN "YEAR" = 2023 THEN "VALUE" END) AS "VAL_2023"
    FROM   agi_vals
),
/* ---------- FHFA HPI Purchase-Only SA (monthly) ---------- */
hpi_vals AS (
    SELECT
        t."VALUE",
        t."DATE"
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES t
    JOIN   phoenix p
           ON t."GEO_ID" = p."GEO_ID"
    WHERE  t."VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND  t."DATE" IN ('2023-01-31','2023-12-31')
),
hpi_change AS (
    SELECT
        MAX(CASE WHEN "DATE" = '2023-01-31' THEN "VALUE" END) AS "VAL_JAN_2023",
        MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END) AS "VAL_DEC_2023"
    FROM   hpi_vals
)
/* ---------- final %-change outputs ---------- */
SELECT
    ROUND(100 * ("VAL_2023"     - "VAL_2022")     / "VAL_2022",     4) AS "AGI_INFLOW_PCT_CHANGE_2023",
    ROUND(100 * ("VAL_DEC_2023" - "VAL_JAN_2023") / "VAL_JAN_2023", 4) AS "HPI_SA_PCT_CHANGE_2023"
FROM agi_change, hpi_change;