WITH distracted_accidents AS (
    SELECT a."state_number", a."state_name", a."year_of_crash" AS "Year",
        COUNT(DISTINCT a."consecutive_number") AS "Accident_Count"
    FROM NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015 a
    JOIN NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2015 d
        ON a."state_number" = d."state_number" AND a."consecutive_number" = d."consecutive_number"
    WHERE d."driver_distracted_by_name" NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
    GROUP BY a."state_number", a."state_name", a."year_of_crash"
    UNION ALL
    SELECT a."state_number", a."state_name", a."year_of_crash" AS "Year",
        COUNT(DISTINCT a."consecutive_number") AS "Accident_Count"
    FROM NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016 a
    JOIN NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2016 d
        ON a."state_number" = d."state_number" AND a."consecutive_number" = d."consecutive_number"
    WHERE d."driver_distracted_by_name" NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
    GROUP BY a."state_number", a."state_name", a."year_of_crash"
),
state_populations AS (
    SELECT TO_NUMBER(us_states."state_fips_code") AS "state_number", SUM(pbz."POPULATION") AS "state_population"
    FROM NHTSA_TRAFFIC_FATALITIES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010 pbz
    JOIN NHTSA_TRAFFIC_FATALITIES_PLUS.UTILITY_US.ZIPCODE_AREA za
        ON pbz."ZIPCODE" = za."zipcode"
    JOIN NHTSA_TRAFFIC_FATALITIES_PLUS.UTILITY_US.US_STATES_AREA us_states
        ON UPPER(za."state_code") = UPPER(us_states."state_abbreviation")
    GROUP BY us_states."state_fips_code"
),
accidents_with_population AS (
    SELECT da."state_number", da."state_name", da."Year", da."Accident_Count", sp."state_population"
    FROM distracted_accidents da
    JOIN state_populations sp
        ON da."state_number" = sp."state_number"
),
rates AS (
    SELECT "Year", "state_name" AS "State",
        ROUND(("Accident_Count" / "state_population") * 100000, 4) AS "Accidents_per_100000_people"
    FROM accidents_with_population
)
SELECT "Year", "State", "Accidents_per_100000_people"
FROM rates
WHERE "Accidents_per_100000_people" IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY "Year" ORDER BY "Accidents_per_100000_people" DESC NULLS LAST) <= 5
ORDER BY "Year", "Accidents_per_100000_people" DESC NULLS LAST;