/*  Second–highest ZIP-code population growth (≥25 k pop) for 2015-2020  */
WITH pop AS (  -- 5-Year ACS total-population estimates
    SELECT
        "GEO_ID"                 AS zip_geo_id,
        YEAR("DATE")             AS yr,
        TO_NUMBER("VALUE")       AS pop
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'          -- total population, 5-yr estimate
      AND "GEO_ID" LIKE 'zip/%'
      AND "DATE"  BETWEEN '2014-12-31' AND '2020-12-31'
),
growth AS (     -- year-over-year growth
    SELECT
        p1.zip_geo_id,
        p1.yr,
        p1.pop,
        p0.pop                                                   AS prev_pop,
        100.0 * (p1.pop - p0.pop) / p0.pop                       AS growth_pct
    FROM pop p1
    JOIN pop p0
      ON p1.zip_geo_id = p0.zip_geo_id
     AND p1.yr        = p0.yr + 1
    WHERE p1.yr BETWEEN 2015 AND 2020        -- growth for 2015-2020
      AND p1.pop >= 25000                    -- population threshold
      AND p0.pop > 0
),
ranked AS (     -- rank by growth within each year
    SELECT
        zip_geo_id,
        yr,
        ROUND(growth_pct, 2) AS growth_pct,
        ROW_NUMBER() OVER (PARTITION BY yr ORDER BY growth_pct DESC NULLS LAST) AS rn
    FROM growth
),
second_highest AS (  -- keep 2nd-highest per year
    SELECT zip_geo_id, yr, growth_pct
    FROM ranked
    WHERE rn = 2
),
/* ---  map ZIP -> State GEO_ID  --------------------------------------- */
zip_state AS (
    SELECT
        "GEO_ID"              AS zip_geo_id,
        MIN("RELATED_GEO_ID") AS state_geo_id
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE "RELATED_LEVEL" = 'State'
      AND "GEO_ID" LIKE 'zip/%'
    GROUP BY "GEO_ID"
),
/* ---  FIPS-to-state-abbreviation lookup  ----------------------------- */
state_map AS (
    SELECT * FROM VALUES
      ('01','AL'),('02','AK'),('04','AZ'),('05','AR'),('06','CA'),('08','CO'),('09','CT'),('10','DE'),
      ('11','DC'),('12','FL'),('13','GA'),('15','HI'),('16','ID'),('17','IL'),('18','IN'),('19','IA'),
      ('20','KS'),('21','KY'),('22','LA'),('23','ME'),('24','MD'),('25','MA'),('26','MI'),('27','MN'),
      ('28','MS'),('29','MO'),('30','MT'),('31','NE'),('32','NV'),('33','NH'),('34','NJ'),('35','NM'),
      ('36','NY'),('37','NC'),('38','ND'),('39','OH'),('40','OK'),('41','OR'),('42','PA'),('44','RI'),
      ('45','SC'),('46','SD'),('47','TN'),('48','TX'),('49','UT'),('50','VT'),('51','VA'),('53','WA'),
      ('54','WV'),('55','WI'),('56','WY'),('60','AS'),('66','GU'),('69','MP'),('72','PR'),('78','VI')
      AS t(fips_code, state_abbr)
)
/* --------------------  final result  --------------------------------- */
SELECT
    REPLACE(sh.zip_geo_id, 'zip/', '')                         AS "ZIP_CODE",
    sm.state_abbr                                              AS "STATE",
    sh.yr                                                      AS "YEAR",
    sh.growth_pct                                              AS "GROWTH_PCT"
FROM second_highest sh
LEFT JOIN zip_state zs
       ON sh.zip_geo_id = zs.zip_geo_id
LEFT JOIN state_map sm
       ON sm.fips_code = REPLACE(zs.state_geo_id, 'geoId/', '')
ORDER BY sh.yr;