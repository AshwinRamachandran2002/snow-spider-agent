WITH pop AS (   -- total population (ACS 5‑Year) for every ZIP code
    SELECT
        "GEO_ID",
        YEAR("DATE")         AS "YEAR",
        TO_NUMBER("VALUE")   AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'       -- total population estimate
      AND "GEO_ID" LIKE 'zip/%'
      AND YEAR("DATE") BETWEEN 2014 AND 2020        -- need t‑1 for growth
), growth AS (   -- compute year‑over‑year growth rate
    SELECT
        p."GEO_ID",
        p."YEAR",
        p."POP",
        LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR") AS "POP_PREV",
        CASE 
            WHEN LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR") IS NULL THEN NULL
            ELSE 100.0 * (p."POP" - LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR"))
                     / LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR")
        END AS "GROWTH_PCT"
    FROM pop p
), filtered AS (  -- keep required years and population ≥ 25,000
    SELECT *
    FROM growth
    WHERE "YEAR" BETWEEN 2015 AND 2020
      AND "POP" >= 25000
), ranked AS (    -- rank by growth rate within each year
    SELECT
        f.*,
        ROW_NUMBER() OVER (PARTITION BY f."YEAR" 
                           ORDER BY f."GROWTH_PCT" DESC NULLS LAST, f."GEO_ID") AS rn
    FROM filtered f
), second_best AS (  -- take the 2nd‑highest growth rate per year
    SELECT *
    FROM ranked
    WHERE rn = 2
), state_join AS (  -- bring in state name via geography relationships
    SELECT
        sb.*,
        gi."GEO_NAME" AS "STATE_NAME"
    FROM second_best sb
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
          ON gr."RELATED_GEO_ID" = sb."GEO_ID"
         AND gr."RELATED_LEVEL"  = 'CensusZipCodeTabulationArea'
         AND gr."LEVEL"          = 'State'
         AND gr."RELATIONSHIP_TYPE" = 'Contains'
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX gi
          ON gi."GEO_ID" = gr."GEO_ID"
)
SELECT
    s."YEAR",
    SUBSTR(s."GEO_ID", 5)                         AS "ZIP_CODE",
    /* map state name to USPS abbreviation */
    CASE UPPER(s."STATE_NAME")
        WHEN 'ALABAMA'              THEN 'AL'
        WHEN 'ALASKA'               THEN 'AK'
        WHEN 'ARIZONA'              THEN 'AZ'
        WHEN 'ARKANSAS'             THEN 'AR'
        WHEN 'CALIFORNIA'           THEN 'CA'
        WHEN 'COLORADO'             THEN 'CO'
        WHEN 'CONNECTICUT'          THEN 'CT'
        WHEN 'DELAWARE'             THEN 'DE'
        WHEN 'DISTRICT OF COL    UM BIA' THEN 'DC'
        WHEN 'FLORIDA'              THEN 'FL'
        WHEN 'GEORGIA'              THEN 'GA'
        WHEN 'HAWAII'               THEN 'HI'
        WHEN 'IDAHO'                THEN 'ID'
        WHEN 'ILLINOIS'             THEN 'IL'
        WHEN 'INDIANA'              THEN 'IN'
        WHEN 'IOWA'                 THEN 'IA'
        WHEN 'KANSAS'               THEN 'KS'
        WHEN 'KENTUCKY'             THEN 'KY'
        WHEN 'LOUISIANA'            THEN 'LA'
        WHEN 'MAINE'                THEN 'ME'
        WHEN 'MARYLAND'             THEN 'MD'
        WHEN 'MASSACHUSETTS'        THEN 'MA'
        WHEN 'MICHIGAN'             THEN 'MI'
        WHEN 'MINNESOTA'            THEN 'MN'
        WHEN 'MISSISSIPPI'          THEN 'MS'
        WHEN 'MISSOURI'             THEN 'MO'
        WHEN 'MONTANA'              THEN 'MT'
        WHEN 'NEBRASKA'             THEN 'NE'
        WHEN 'NEVADA'               THEN 'NV'
        WHEN 'NEW HAMPSHIRE'        THEN 'NH'
        WHEN 'NEW JERSEY'           THEN 'NJ'
        WHEN 'NEW MEXICO'           THEN 'NM'
        WHEN 'NEW YORK'             THEN 'NY'
        WHEN 'NORTH CAROLINA'       THEN 'NC'
        WHEN 'NORTH DAKOTA'         THEN 'ND'
        WHEN 'OHIO'                 THEN 'OH'
        WHEN 'OKLAHOMA'             THEN 'OK'
        WHEN 'OREGON'               THEN 'OR'
        WHEN 'PENNSYLVANIA'         THEN 'PA'
        WHEN 'RHODE ISLAND'         THEN 'RI'
        WHEN 'SOUTH CAROLINA'       THEN 'SC'
        WHEN 'SOUTH DAKOTA'         THEN 'SD'
        WHEN 'TENNESSEE'            THEN 'TN'
        WHEN 'TEXAS'                THEN 'TX'
        WHEN 'UTAH'                 THEN 'UT'
        WHEN 'VERMONT'              THEN 'VT'
        WHEN 'VIRGINIA'             THEN 'VA'
        WHEN 'WASHINGTON'           THEN 'WA'
        WHEN 'WEST VIRGINIA'        THEN 'WV'
        WHEN 'WISCONSIN'            THEN 'WI'
        WHEN 'WYOMING'              THEN 'WY'
        ELSE NULL
    END                                       AS "STATE_ABBR",
    ROUND(s."GROWTH_PCT", 4)                  AS "ANNUAL_GROWTH_RATE_PCT"
FROM state_join s
ORDER BY s."YEAR";