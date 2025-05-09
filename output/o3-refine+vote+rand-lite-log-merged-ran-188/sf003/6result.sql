WITH pop AS (   /* 5‑year ACS total‑population estimates for ZIP Coded Tabulation Areas (ZCTAs) */
    SELECT  
        TO_NUMBER(LEFT("DATE",4))           AS "YEAR",            -- year portion of DATE (YYYY‑12‑31)
        "GEO_ID",                                                  -- e.g. zip/30301
        "VALUE"::FLOAT                      AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'                           -- Total population (estimate)
      AND "GEO_ID" LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'             -- need 2014‑2020 to build 2015‑2020 growth
),
growth AS (   /* year‑over‑year % growth, keep POP ≥ 25 000 in the CURRENT year */
    SELECT
        p."YEAR",
        p."GEO_ID",
        p."POP",
        LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR")   AS "POP_LAG",
        CASE 
            WHEN LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR") > 0
            THEN 100.0 * (p."POP" 
                         - LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR"))
                       / LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR")
        END                                                        AS "GROWTH_RATE_PCT"
    FROM pop p
),
qualified AS (   /* keep 2015‑2020 rows with required population threshold and non‑null growth */
    SELECT *
    FROM growth
    WHERE "YEAR" BETWEEN 2015 AND 2020
      AND "POP" >= 25000
      AND "GROWTH_RATE_PCT" IS NOT NULL
),
ranked AS (   /* rank by growth rate within each year */
    SELECT
        q.*,
        DENSE_RANK() OVER (PARTITION BY q."YEAR" 
                           ORDER BY q."GROWTH_RATE_PCT" DESC) AS "RNK"
    FROM qualified q
),
with_state AS (   /* attach state‑level GEO_ID then derive two‑letter abbreviation */
    SELECT
        r."YEAR",
        REGEXP_SUBSTR(r."GEO_ID",'[0-9]{5}')           AS "ZIP",
        gi_state."ISO_3166_2_CODE",                    -- e.g. 'US‑CA'
        r."GROWTH_RATE_PCT"
    FROM ranked r
    /* find the State that CONTAINS the ZIP */
    LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
           ON gr."RELATED_GEO_ID" = r."GEO_ID"
          AND gr."RELATIONSHIP_TYPE" = 'Contains'
          AND gr."LEVEL" = 'State'
    LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX gi_state
           ON gi_state."GEO_ID" = gr."GEO_ID"
    WHERE r."RNK" = 2
)
SELECT  
    "YEAR",
    "ZIP"                                          AS "ZIP_CODE",
    UPPER(SUBSTR("ISO_3166_2_CODE",4))             AS "STATE_ABBR",   -- take 'CA' from 'US‑CA'
    ROUND("GROWTH_RATE_PCT",4)                     AS "ANNUAL_GROWTH_RATE_PCT"
FROM with_state
ORDER BY "YEAR";