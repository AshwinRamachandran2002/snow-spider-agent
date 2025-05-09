/*--------------------------------------------------------------------
  Percent-change (2023) for:
    1) Gross Income Inflow (total AGI, all ages & AGI classes)
    2) FHFA HPI ‑ purchase-only, seasonally-adjusted
   Geography: Phoenix-Mesa-Scottsdale, AZ Metro Area  (CBSA GEO_ID: geoId/C38060)
--------------------------------------------------------------------*/
WITH phoenix AS (
    SELECT 'geoId/C38060'::TEXT AS "GEO_ID"
),

/* ----------------  Gross-income inflow (IRS)  ------------------- */
inflow AS (   -- pull start- and end-of-period values
    SELECT
        CASE WHEN "DATE" = '2022-12-31' THEN 'START' ELSE 'END' END AS period,
        "VALUE"
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES  t
    JOIN   phoenix p  ON t."GEO_ID" = p."GEO_ID"
    WHERE  t."VARIABLE_NAME" ILIKE 'Inflow%adjusted gross income%All AGI classes%'
      AND  t."UNIT" = 'USD'
      AND  t."DATE" IN ('2022-12-31', '2023-12-31')
),
inflow_change AS (
    SELECT
        MAX(CASE WHEN period = 'START' THEN "VALUE" END) AS inflow_start,
        MAX(CASE WHEN period = 'END'   THEN "VALUE" END) AS inflow_end
    FROM inflow
),

/* --------  FHFA House Price Index (purchase-only, SA)  ---------- */
hpi AS (      -- use monthly series to match 1-Jan vs 31-Dec window
    SELECT
        CASE WHEN "DATE" = '2023-01-31' THEN 'START' ELSE 'END' END AS period,
        CAST("VALUE" AS FLOAT) AS "VALUE"
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES  t
    JOIN   phoenix p  ON t."GEO_ID" = p."GEO_ID"
    WHERE  t."VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND  t."DATE" IN ('2023-01-31', '2023-12-31')
),
hpi_change AS (
    SELECT
        MAX(CASE WHEN period = 'START' THEN "VALUE" END) AS hpi_start,
        MAX(CASE WHEN period = 'END'   THEN "VALUE" END) AS hpi_end
    FROM hpi
)

/* --------------------  Final percent changes -------------------- */
SELECT
    (inflow_change.inflow_end - inflow_change.inflow_start)
        / inflow_change.inflow_start * 100         AS "Gross_Income_Inflow_%_Change_2023",
    (hpi_change.hpi_end - hpi_change.hpi_start)
        / hpi_change.hpi_start * 100               AS "HPI_PurchaseOnly_SA_%_Change_2023"
FROM inflow_change
CROSS JOIN hpi_change;