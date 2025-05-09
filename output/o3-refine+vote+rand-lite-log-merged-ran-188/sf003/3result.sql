WITH pop AS (
    /* 5‑year ACS total‑population estimates for ZCTAs, 2014‑2020                     */
    SELECT
        "GEO_ID",          /* e.g. 'zip/30301'                                       */
        "DATE",
        TO_NUMBER("VALUE") AS population
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'          -- total population, 5‑year estimate
      AND "GEO_ID"  LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
), pop_with_prev AS (
    /* add previous‑year population for each ZCTA                                     */
    SELECT
        p.*,
        LAG(population) OVER (PARTITION BY "GEO_ID" ORDER BY "DATE") AS pop_prev
    FROM pop p
), growth AS (
    /* annual growth rate, keep 2015‑2020 & pop ≥ 25 000                              */
    SELECT
        "GEO_ID",
        YEAR("DATE")                     AS yr,
        population,
        pop_prev,
        (population - pop_prev) / pop_prev * 100      AS growth_rate
    FROM pop_with_prev
    WHERE YEAR("DATE") BETWEEN 2015 AND 2020
      AND population >= 25000
      AND pop_prev    IS NOT NULL
      AND pop_prev    > 0
), zip_to_state AS (
    /* map each ZCTA to its state GEO_ID                                              */
    SELECT
        r."RELATED_GEO_ID" AS zip_geo_id,   -- 'zip/…..'
        r."GEO_ID"         AS state_geo_id  -- 'geoId/06'
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS r
    WHERE r."LEVEL"          = 'State'
      AND r."RELATED_LEVEL"  = 'CensusZipCodeTabulationArea'
      AND r."RELATIONSHIP_TYPE" = 'Contains'
), enriched AS (
    SELECT
        g.yr,
        SUBSTR(g."GEO_ID",5)                 AS zip_code,          -- strip 'zip/'
        SUBSTR(s.state_geo_id,7,2)           AS state_fips,        -- e.g. '06'
        g.growth_rate
    FROM growth g
    LEFT JOIN zip_to_state s
           ON s.zip_geo_id = g."GEO_ID"
), ranked AS (
    /* rank ZCTAs by growth rate within each year                                     */
    SELECT
        yr,
        zip_code,
        /* FIPS‑to‑state‑abbreviation mapping                                         */
        CASE state_fips
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
        END                                         AS state_abbr,
        growth_rate,
        ROW_NUMBER() OVER (PARTITION BY yr ORDER BY growth_rate DESC NULLS LAST, zip_code) AS rn
    FROM enriched
)
SELECT
    yr                        AS "YEAR",
    zip_code                  AS "ZIP_CODE",
    state_abbr                AS "STATE",
    ROUND(growth_rate,4)      AS "ANNUAL_GROWTH_RATE_PERCENT"
FROM ranked
WHERE rn = 2                              -- second‑highest growth rate
ORDER BY yr;