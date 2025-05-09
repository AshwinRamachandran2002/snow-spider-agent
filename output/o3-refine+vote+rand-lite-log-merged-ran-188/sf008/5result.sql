/*  -------------------------------------------------------------
    % CHANGE (JAN-1-2023 ≈ 2022-12-31  →  2023-12-31) IN:
      1.  Gross-income inflow  (sum of adjusted-gross-income amounts
          across all Phoenix-metro ZIPs)
      2.  Seasonally-adjusted purchase-only FHFA HPI for Phoenix-metro
    ------------------------------------------------------------- */

WITH phoenix_zips AS (   -- every ZIP fully contained in the CBSA
    SELECT  "RELATED_GEO_ID"  AS "ZIP_GEO_ID"
    FROM    US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE   "GEO_ID"          = 'geoId/C38060'               -- Phoenix-Mesa-Scottsdale CBSA
      AND   "RELATED_LEVEL"   = 'CensusZipCodeTabulationArea'
      AND   "RELATIONSHIP_TYPE" = 'Contains'
),

/* --------  GROSS-INCOME INFLOW  ------------------------------------------- */
agi_values AS (          -- aggregate AGI for start- & end-of-year points
    SELECT
        CASE WHEN "DATE" = '2022-12-31' THEN 'START'
             WHEN "DATE" = '2023-12-31' THEN 'END'   END     AS "PERIOD",
        SUM("VALUE")                                       AS "AGI"
    FROM    US_REAL_ESTATE.CYBERSYN.IRS_INDIVIDUAL_INCOME_TIMESERIES  t
    JOIN    phoenix_zips z
           ON t."GEO_ID" = z."ZIP_GEO_ID"
    WHERE   t."VARIABLE" ILIKE 'Adjusted_gross_income_-_Amount%'      -- AGI amounts
      AND   t."DATE" IN ('2022-12-31','2023-12-31')
    GROUP BY  "PERIOD"
),
agi_start_end AS (
    SELECT
        MAX(CASE WHEN "PERIOD"='START' THEN "AGI" END)  AS "AGI_START",
        MAX(CASE WHEN "PERIOD"='END'   THEN "AGI" END)  AS "AGI_END"
    FROM agi_values
),

/* --------  FHFA HPI  ------------------------------------------------------- */
hpi_start_end AS (       -- first & last 2023 observations (monthly OR quarterly)
    SELECT
        MIN_BY("VALUE","DATE")  AS "HPI_START",
        MAX_BY("VALUE","DATE")  AS "HPI_END"
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE  "GEO_ID"   = 'geoId/C38060'
      AND  "VARIABLE" ILIKE '%purchase-only%'     -- purchase-only series
      AND  "VARIABLE" ILIKE '%_SA'                -- seasonally adjusted
      AND  "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
)

SELECT
    /* % change = (end – start) / start * 100 */
    ("AGI_END" - "AGI_START") / "AGI_START" * 100  AS "PCT_CHANGE_AGI_INFLOW_2023",
    ("HPI_END" - "HPI_START") / "HPI_START" * 100  AS "PCT_CHANGE_HPI_2023"
FROM agi_start_end
CROSS JOIN hpi_start_end;