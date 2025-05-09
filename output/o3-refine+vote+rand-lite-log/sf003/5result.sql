/*--------------------------------------------------------------------
  Second‑highest annual population growth (>=25k pop) by ZIP (ZCTA)
  for each year 2015‑2020 using ACS 5‑Year estimates
--------------------------------------------------------------------*/
WITH pop AS (   -- total population per ZIP & year
    SELECT
        "GEO_ID"                           AS zip_geo_id,          -- e.g. zip/77002
        YEAR("DATE")                       AS yr,                  -- ACS 5‑yr estimate year
        TO_NUMBER("VALUE")                 AS population
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'            -- total population (estimate, 5‑yr)
      AND YEAR("DATE") BETWEEN 2014 AND 2020        -- need t‑1 for growth calc
      AND LEFT("GEO_ID",4) = 'zip/'                 -- keep only ZCTA level
),
growth AS (      -- compute YoY growth rates
    SELECT
        p.zip_geo_id,
        p.yr,
        p.population,
        LAG(p.population) OVER (PARTITION BY p.zip_geo_id ORDER BY p.yr)          AS prev_pop,
        (p.population
         - LAG(p.population) OVER (PARTITION BY p.zip_geo_id ORDER BY p.yr))
         / NULLIF(LAG(p.population) OVER (PARTITION BY p.zip_geo_id ORDER BY p.yr),0) AS growth_rate
    FROM pop p
),
filtered AS (     -- years 2015‑2020, pop ≥ 25 000 & valid previous pop
    SELECT *
    FROM growth
    WHERE yr BETWEEN 2015 AND 2020
      AND population >= 25000
      AND prev_pop IS NOT NULL
      AND prev_pop > 0
),
/* ----------  derive state abbreviation for every ZIP --------------*/
state_abbr_map AS (      -- FIPS‑to‑postal code reference
    SELECT * FROM VALUES
    ('01','AL'),('02','AK'),('04','AZ'),('05','AR'),('06','CA'),('08','CO'),
    ('09','CT'),('10','DE'),('11','DC'),('12','FL'),('13','GA'),('15','HI'),
    ('16','ID'),('17','IL'),('18','IN'),('19','IA'),('20','KS'),('21','KY'),
    ('22','LA'),('23','ME'),('24','MD'),('25','MA'),('26','MI'),('27','MN'),
    ('28','MS'),('29','MO'),('30','MT'),('31','NE'),('32','NV'),('33','NH'),
    ('34','NJ'),('35','NM'),('36','NY'),('37','NC'),('38','ND'),('39','OH'),
    ('40','OK'),('41','OR'),('42','PA'),('44','RI'),('45','SC'),('46','SD'),
    ('47','TN'),('48','TX'),('49','UT'),('50','VT'),('51','VA'),('53','WA'),
    ('54','WV'),('55','WI'),('56','WY')
    AS t(fips,state_abbr)
),
zip_state AS (    -- map each ZIP to its containing state
    SELECT DISTINCT
        gr."RELATED_GEO_ID"                       AS zip_geo_id,
        m.state_abbr
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS            gr
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX                    g
           ON g."GEO_ID" = gr."GEO_ID" AND g."LEVEL" = 'State'
    JOIN state_abbr_map                                               m
           ON SUBSTR(g."GEO_ID",7,2) = m.fips          -- extract 2‑digit FIPS
    WHERE gr."RELATIONSHIP_TYPE" = 'Contains'
      AND LEFT(gr."RELATED_GEO_ID",4) = 'zip/'
),
ranked AS (       -- rank by growth rate each year
    SELECT
        f.yr,
        f.zip_geo_id,
        zs.state_abbr,
        f.growth_rate * 100                    AS growth_pct,
        DENSE_RANK() OVER (PARTITION BY f.yr ORDER BY f.growth_rate DESC NULLS LAST) AS rnk
    FROM filtered f
    LEFT JOIN zip_state zs  ON zs.zip_geo_id = f.zip_geo_id
)
SELECT
    r.yr                                 AS "YEAR",
    SUBSTR(r.zip_geo_id,5)               AS "ZIP_CODE",
    COALESCE(r.state_abbr,'')            AS "STATE_ABBR",
    ROUND(r.growth_pct,4)                AS "ANNUAL_GROWTH_RATE_PCT"
FROM ranked r
WHERE r.rnk = 2                          -- second‑highest growth
ORDER BY r.yr ASC;