WITH population AS (
    /* 2020 total-population for the seven countries               */
    SELECT
        DECODE("country_name",
               'Iran, Islamic Rep.', 'Iran',
               'United States',      'United States',
               'China',              'China',
               'France',             'France',
               'Italy',              'Italy',
               'Spain',              'Spain',
               'Germany',            'Germany')         AS "country",
        SUM("value")                                   AS "population_2020"
    FROM   COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE  "indicator_name" ILIKE '%Population, total%'
      AND  "year" = 2020
      AND  "country_name" IN ('United States',
                              'France',
                              'China',
                              'Italy',
                              'Spain',
                              'Germany',
                              'Iran, Islamic Rep.')
    GROUP BY "country"
),
cases AS (
    /* Confirmed-case totals as of 20-Apr-2020 for the same countries */
    SELECT
        DECODE("country_or_region",
               'US',    'United States',
               'Iran',  'Iran',
               'China', 'China',
               'France','France',
               'Italy', 'Italy',
               'Spain', 'Spain',
               'Germany','Germany')                    AS "country",
        SUM("_4_20_20"::NUMBER)                        AS "confirmed_cases_4_20_2020"
    FROM   COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.CONFIRMED_CASES
    WHERE  "country_or_region" IN ('US',
                                   'France',
                                   'China',
                                   'Italy',
                                   'Spain',
                                   'Germany',
                                   'Iran')
    GROUP BY "country"
)
SELECT
       c."country",
       c."confirmed_cases_4_20_2020",
       p."population_2020",
       ROUND( (c."confirmed_cases_4_20_2020" / p."population_2020") * 100000, 4) AS "cases_per_100k"
FROM   cases      c
JOIN   population p
  ON   c."country" = p."country"
ORDER BY c."country";