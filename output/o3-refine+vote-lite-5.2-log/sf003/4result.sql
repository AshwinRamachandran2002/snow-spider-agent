/* ----------------------------------------------------------------------
   Second‑highest annual population growth (5‑Year ACS estimates) by ZCTA
   for each year 2015‑2020, limited to ZCTAs with ≥ 25,000 residents.
------------------------------------------------------------------------ */
WITH pop AS (   /* 5‑Year ACS total‑population estimates for every ZCTA */
    SELECT
        "GEO_ID",                                   -- e.g. zip/78744
        EXTRACT(year FROM "DATE")      AS "YEAR",   -- numeric year
        "VALUE"::FLOAT                AS "POP"      -- population
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'            -- total population, 5‑yr estimate
      AND "GEO_ID" LIKE 'zip/%'                     -- keep only ZCTAs
      AND EXTRACT(year FROM "DATE") BETWEEN 2014 AND 2020   -- need t‑1 year for 2015 calc
),
growth AS (      /* year‑over‑year growth rate */
    SELECT
        p."GEO_ID",
        p."YEAR",
        p."POP",
        LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR") AS "POP_PREV"
    FROM pop p
),
growth_rate AS ( /* compute % growth; keep rows for 2015‑2020 & POP ≥ 25k */
    SELECT
        g."GEO_ID",
        g."YEAR",
        CASE WHEN g."POP_PREV" > 0
             THEN 100.0 * (g."POP" - g."POP_PREV") / g."POP_PREV"
        END AS "GROWTH_PCT"
    FROM growth g
    WHERE g."YEAR" BETWEEN 2015 AND 2020
      AND g."POP" >= 25000
      AND g."POP_PREV" IS NOT NULL
),
state_lookup AS ( /* map each ZCTA to its containing state & derive abbreviation */
    SELECT
        r."RELATED_GEO_ID"        AS "GEO_ID_ZIP",
        SPLIT_PART(s."ISO_3166_2_CODE",'-',2) AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS r
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX        s
          ON s."GEO_ID" = r."GEO_ID"
    WHERE r."RELATED_LEVEL"   = 'CensusZipCodeTabulationArea'
      AND r."LEVEL"           = 'State'
      AND r."RELATIONSHIP_TYPE" = 'Contains'
)
SELECT
    SUBSTR(gr."GEO_ID",5)            AS "ZIP_CODE",
    sl."STATE_ABBR"                  AS "STATE",
    ROUND(gr."GROWTH_PCT",4)         AS "ANNUAL_GROWTH_RATE_PCT",
    gr."YEAR"
FROM (
    SELECT  /* rank ZCTAs by growth within each year */
        gr.*,
        ROW_NUMBER() OVER (PARTITION BY gr."YEAR"
                           ORDER BY gr."GROWTH_PCT" DESC NULLS LAST,
                                    gr."GEO_ID") AS "RN"
    FROM growth_rate gr
) gr
LEFT JOIN state_lookup sl
       ON sl."GEO_ID_ZIP" = gr."GEO_ID"
WHERE gr."RN" = 2     -- second‑highest per year
ORDER BY gr."YEAR";