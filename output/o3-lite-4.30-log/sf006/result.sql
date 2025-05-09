WITH "states" AS (
    SELECT column1::text AS "state"
    FROM VALUES
        ('AL'),('AK'),('AZ'),('AR'),('CA'),('CO'),('CT'),('DE'),('FL'),('GA'),
        ('HI'),('ID'),('IL'),('IN'),('IA'),('KS'),('KY'),('LA'),('ME'),('MD'),
        ('MA'),('MI'),('MN'),('MS'),('MO'),('MT'),('NE'),('NV'),('NH'),('NJ'),
        ('NM'),('NY'),('NC'),('ND'),('OH'),('OK'),('OR'),('PA'),('RI'),('SC'),
        ('SD'),('TN'),('TX'),('UT'),('VT'),('VA'),('WA'),('WV'),('WI'),('WY')
),
"cnt_2020" AS (
    SELECT
        "STATE_ABBREVIATION"                     AS "state",
        COUNT(*)                                 AS "active_2020_03_01"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE
        "CATEGORY" = 'Branch'
        AND "START_DATE" <= '2020-03-01'
        AND ("END_DATE" IS NULL OR "END_DATE" >= '2020-03-01')
    GROUP BY "STATE_ABBREVIATION"
),
"cnt_2021" AS (
    SELECT
        "STATE_ABBREVIATION"                     AS "state",
        COUNT(*)                                 AS "active_2021_12_31"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE
        "CATEGORY" = 'Branch'
        AND "START_DATE" <= '2021-12-31'
        AND ("END_DATE" IS NULL OR "END_DATE" >= '2021-12-31')
    GROUP BY "STATE_ABBREVIATION"
)
SELECT
    s."state",
    COALESCE(c20."active_2020_03_01", 0)                         AS "active_2020_03_01",
    COALESCE(c21."active_2021_12_31", 0)                         AS "active_2021_12_31",
    ROUND(
        (COALESCE(c21."active_2021_12_31", 0) - COALESCE(c20."active_2020_03_01", 0))
        / NULLIF(COALESCE(c20."active_2020_03_01", 0), 0) * 100
    , 4)                                                         AS "percent_change"
FROM "states"  s
LEFT JOIN "cnt_2020" c20 ON s."state" = c20."state"
LEFT JOIN "cnt_2021" c21 ON s."state" = c21."state"
ORDER BY s."state";