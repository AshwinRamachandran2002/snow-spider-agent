/* 2nd‑highest ZIP‑code population growth (≥25,000 pop) per year, 2015‑2020 */

WITH base AS (   -- yearly ACS 5‑Yr population for ZIP Code Tabulation Areas
    SELECT
        "GEO_ID",                -- format: zip/12345
        "DATE",
        "VALUE"::FLOAT AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'       -- total population, 5‑year estimate
      AND "GEO_ID" LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
),
lagged AS (      -- previous year’s population
    SELECT
        "GEO_ID",
        "DATE",
        "POP",
        LAG("POP") OVER (PARTITION BY "GEO_ID" ORDER BY "DATE") AS "POP_PREV"
    FROM base
),
growth AS (      -- annual growth %, keep ZIPs with ≥25 000 population
    SELECT
        l."GEO_ID",
        l."DATE",
        (l."POP" - l."POP_PREV") / l."POP_PREV" * 100 AS "GROWTH_PCT"
    FROM lagged l
    WHERE l."DATE" >= '2015-12-31'
      AND l."POP_PREV" IS NOT NULL
      AND l."POP"      >= 25000
),
zip_state AS (   -- map ZIP ZCTAs to state GEO_IDs
    SELECT
        r."GEO_ID"         AS "ZIP_GEO_ID",
        r."RELATED_GEO_ID" AS "STATE_GEO_ID"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS r
    WHERE r."LEVEL"             = 'CensusZipCodeTabulationArea'
      AND r."RELATED_LEVEL"     = 'State'
      AND r."RELATIONSHIP_TYPE" = 'Overlaps'
),
state_abbr AS (  -- derive two‑letter state abbreviations from FIPS codes
    SELECT
        "GEO_ID",
        CASE SUBSTR("GEO_ID", 7, 2)
            WHEN '01' THEN 'AL' WHEN '02' THEN 'AK' WHEN '04' THEN 'AZ'
            WHEN '05' THEN 'AR' WHEN '06' THEN 'CA' WHEN '08' THEN 'CO'
            WHEN '09' THEN 'CT' WHEN '10' THEN 'DE' WHEN '11' THEN 'DC'
            WHEN '12' THEN 'FL' WHEN '13' THEN 'GA' WHEN '15' THEN 'HI'
            WHEN '16' THEN 'ID' WHEN '17' THEN 'IL' WHEN '18' THEN 'IN'
            WHEN '19' THEN 'IA' WHEN '20' THEN 'KS' WHEN '21' THEN 'KY'
            WHEN '22' THEN 'LA' WHEN '23' THEN 'ME' WHEN '24' THEN 'MD'
            WHEN '25' THEN 'MA' WHEN '26' THEN 'MI' WHEN '27' THEN 'MN'
            WHEN '28' THEN 'MS' WHEN '29' THEN 'MO' WHEN '30' THEN 'MT'
            WHEN '31' THEN 'NE' WHEN '32' THEN 'NV' WHEN '33' THEN 'NH'
            WHEN '34' THEN 'NJ' WHEN '35' THEN 'NM' WHEN '36' THEN 'NY'
            WHEN '37' THEN 'NC' WHEN '38' THEN 'ND' WHEN '39' THEN 'OH'
            WHEN '40' THEN 'OK' WHEN '41' THEN 'OR' WHEN '42' THEN 'PA'
            WHEN '44' THEN 'RI' WHEN '45' THEN 'SC' WHEN '46' THEN 'SD'
            WHEN '47' THEN 'TN' WHEN '48' THEN 'TX' WHEN '49' THEN 'UT'
            WHEN '50' THEN 'VT' WHEN '51' THEN 'VA' WHEN '53' THEN 'WA'
            WHEN '54' THEN 'WV' WHEN '55' THEN 'WI' WHEN '56' THEN 'WY'
            WHEN '60' THEN 'AS' WHEN '66' THEN 'GU' WHEN '69' THEN 'MP'
            WHEN '72' THEN 'PR' WHEN '78' THEN 'VI'
        END AS "STATE_ABBREVIATION"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX
    WHERE "LEVEL" = 'State'
),
ranked AS (      -- rank ZIPs by growth each year
    SELECT
        g."GEO_ID"             AS "ZIP_GEO_ID",
        zs."STATE_GEO_ID",
        g."DATE",
        g."GROWTH_PCT",
        ROW_NUMBER() OVER (PARTITION BY TO_CHAR(g."DATE",'YYYY')
                           ORDER BY g."GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM growth g
    JOIN zip_state zs ON g."GEO_ID" = zs."ZIP_GEO_ID"
)
SELECT
    SUBSTR(r."ZIP_GEO_ID", 5)                       AS zip_code,
    sa."STATE_ABBREVIATION"                         AS state_abbreviation,
    TO_CHAR(r."DATE", 'YYYY')                       AS year,
    ROUND(r."GROWTH_PCT", 4)                        AS annual_growth_rate_percentage
FROM ranked r
JOIN state_abbr sa ON r."STATE_GEO_ID" = sa."GEO_ID"
WHERE r."RN" = 2
ORDER BY year;