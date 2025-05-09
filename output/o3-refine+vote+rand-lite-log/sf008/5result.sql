/*---------------------------------------------------------------
  % change (Jan‑1‑2023 → Dec‑31‑2023) for
  1) Gross Income Inflow  (IRS county‑level migration, summed to CBSA)
  2) FHFA Purchase‑Only HPI (seasonally‑adjusted, monthly CBSA series)
  Geography: Phoenix‑Mesa‑Scottsdale, AZ Metro Area  (CBSA = geoId/C38060)
-----------------------------------------------------------------*/
WITH metro_counties AS (   -- counties that make up the Phoenix CBSA
    SELECT DISTINCT
           CASE 
               WHEN "GEO_ID" = 'geoId/C38060'            -- CBSA contains county
                    AND "RELATIONSHIP_TYPE" = 'Contains'
                    AND "RELATED_LEVEL" = 'County'
               THEN "RELATED_GEO_ID"
               WHEN "RELATED_GEO_ID" = 'geoId/C38060'    -- county overlaps CBSA
                    AND "RELATIONSHIP_TYPE" = 'Overlaps'
                    AND "LEVEL" = 'County'
               THEN "GEO_ID"
           END AS county_id
    FROM US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE (   "GEO_ID" = 'geoId/C38060'   OR   "RELATED_GEO_ID" = 'geoId/C38060' )
),
/*-------------------  Gross‑income inflow ----------------------*/
gross AS (
    SELECT 
        CASE WHEN "DATE" = '2022-12-31' THEN 'start'
             WHEN "DATE" = '2023-12-31' THEN 'end'
        END                               AS period,
        SUM("VALUE")                      AS agi_usd
    FROM US_REAL_ESTATE.CYBERSYN.IRS_ORIGIN_DESTINATION_MIGRATION_TIMESERIES
    WHERE "TO_GEO_ID"    IN (SELECT county_id FROM metro_counties)
      AND "VARIABLE_NAME" = 'Adjusted Gross Income'
      AND "DATE"         IN ('2022-12-31','2023-12-31')
      AND "SUPPRESSED"   = 0
    GROUP BY period
),
gross_pct AS (
    SELECT
        (MAX(CASE WHEN period='end'   THEN agi_usd END) -
         MAX(CASE WHEN period='start' THEN agi_usd END))
        * 100.0
        / NULLIF(MAX(CASE WHEN period='start' THEN agi_usd END),0)   
        AS pct_change_gross_inflow
    FROM gross
),
/*-------------------  FHFA purchase‑only HPI -------------------*/
hpi AS (
    SELECT 
        CASE WHEN "DATE" = '2023-01-31' THEN 'start'
             WHEN "DATE" = '2023-12-31' THEN 'end'
        END                    AS period,
        "VALUE" :: FLOAT       AS hpi_val
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"   = 'geoId/C38060'
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_monthly_SA'
      AND "DATE"     IN ('2023-01-31','2023-12-31')
),
hpi_pct AS (
    SELECT
        (MAX(CASE WHEN period='end'   THEN hpi_val END) -
         MAX(CASE WHEN period='start' THEN hpi_val END))
        * 100.0
        / NULLIF(MAX(CASE WHEN period='start' THEN hpi_val END),0)
        AS pct_change_hpi
    FROM hpi
)
/*---------------------------  Output ---------------------------*/
SELECT 
    g.pct_change_gross_inflow    AS "GROSS_INFLOW_PCT_CHANGE_2023",
    h.pct_change_hpi             AS "HPI_PCT_CHANGE_2023"
FROM gross_pct g
CROSS JOIN hpi_pct h;