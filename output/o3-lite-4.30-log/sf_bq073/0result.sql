WITH state_names AS (
    SELECT column1 AS code, column2 AS name
    FROM VALUES
        ('01','Alabama'), ('02','Alaska'), ('04','Arizona'), ('05','Arkansas'),
        ('06','California'), ('08','Colorado'), ('09','Connecticut'), ('10','Delaware'),
        ('11','District of Columbia'), ('12','Florida'), ('13','Georgia'), ('15','Hawaii'),
        ('16','Idaho'), ('17','Illinois'), ('18','Indiana'), ('19','Iowa'),
        ('20','Kansas'), ('21','Kentucky'), ('22','Louisiana'), ('23','Maine'),
        ('24','Maryland'), ('25','Massachusetts'), ('26','Michigan'), ('27','Minnesota'),
        ('28','Mississippi'), ('29','Missouri'), ('30','Montana'), ('31','Nebraska'),
        ('32','Nevada'), ('33','New Hampshire'), ('34','New Jersey'), ('35','New Mexico'),
        ('36','New York'), ('37','North Carolina'), ('38','North Dakota'), ('39','Ohio'),
        ('40','Oklahoma'), ('41','Oregon'), ('42','Pennsylvania'), ('44','Rhode Island'),
        ('45','South Carolina'), ('46','South Dakota'), ('47','Tennessee'), ('48','Texas'),
        ('49','Utah'), ('50','Vermont'), ('51','Virginia'), ('53','Washington'),
        ('54','West Virginia'), ('55','Wisconsin'), ('56','Wyoming'),
        ('60','American Samoa'), ('66','Guam'), ('69','Northern Mariana Islands'),
        ('72','Puerto Rico'), ('78','Virgin Islands')
),
/* ZIP‑level median‑income change (not displayed but included per instructions) */
income_diff AS (
    SELECT 
        LEFT(z15."geo_id", 2)                                           AS state_fips,
        AVG(z18."median_income" - z15."median_income")                  AS avg_income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z18
          ON z18."geo_id" = z15."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
    GROUP BY 1
),
/* 2017 vulnerable employment counts */
vulnerable AS (
    SELECT
        s."geo_id"                                                      AS state_fips,
        /* keep four‑decimal precision */
        ROUND(s."employed_wholesale_trade" * 0.38, 4)                   AS vulnerable_wholesale_workers,
        ROUND(s."employed_manufacturing"   * 0.41, 4)                   AS vulnerable_manufacturing_workers
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2017_1YR" s
)

/* final list */
SELECT
    COALESCE(sn.name, v.state_fips)                                     AS state,
    v.vulnerable_wholesale_workers,
    v.vulnerable_manufacturing_workers,
    ROUND(v.vulnerable_wholesale_workers + v.vulnerable_manufacturing_workers ,4)
        AS total_vulnerable_workers
FROM vulnerable v
LEFT JOIN state_names sn  ON sn.code = v.state_fips
/* join to income_diff if future filtering/analysis needed */
LEFT JOIN income_diff id  ON id.state_fips = v.state_fips
ORDER BY total_vulnerable_workers DESC NULLS LAST, state;