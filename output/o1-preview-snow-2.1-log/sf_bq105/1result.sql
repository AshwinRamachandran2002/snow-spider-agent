WITH distracted_accidents AS (
  SELECT a."state_name", COUNT(*) AS "distracted_accidents", '2015' AS "Year"
  FROM "NHTSA_TRAFFIC_FATALITIES_PLUS"."NHTSA_TRAFFIC_FATALITIES"."DISTRACT_2015" d
  JOIN "NHTSA_TRAFFIC_FATALITIES_PLUS"."NHTSA_TRAFFIC_FATALITIES"."ACCIDENT_2015" a
    ON d."state_number" = a."state_number" AND d."consecutive_number" = a."consecutive_number"
  WHERE d."driver_distracted_by_name" NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a."state_name"
  UNION ALL
  SELECT a."state_name", COUNT(*) AS "distracted_accidents", '2016' AS "Year"
  FROM "NHTSA_TRAFFIC_FATALITIES_PLUS"."NHTSA_TRAFFIC_FATALITIES"."DISTRACT_2016" d
  JOIN "NHTSA_TRAFFIC_FATALITIES_PLUS"."NHTSA_TRAFFIC_FATALITIES"."ACCIDENT_2016" a
    ON d."state_number" = a."state_number" AND d."consecutive_number" = a."consecutive_number"
  WHERE d."driver_distracted_by_name" NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a."state_name"
),
state_populations AS (
  SELECT za."state_name", SUM(pz."POPULATION") AS "state_population"
  FROM "NHTSA_TRAFFIC_FATALITIES_PLUS"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010" pz
  JOIN "NHTSA_TRAFFIC_FATALITIES_PLUS"."UTILITY_US"."ZIPCODE_AREA" za
    ON pz."ZIPCODE" = za."zipcode"
  GROUP BY za."state_name"
)
SELECT "Year", "State", "Accidents_per_100000_people"
FROM (
  SELECT da."Year", da."state_name" AS "State",
         ROUND((da."distracted_accidents" / sp."state_population") * 100000, 4) AS "Accidents_per_100000_people",
         ROW_NUMBER() OVER (PARTITION BY da."Year" ORDER BY (da."distracted_accidents" / sp."state_population") DESC NULLS LAST) AS "Rank"
  FROM distracted_accidents da
  JOIN state_populations sp
    ON da."state_name" = sp."state_name"
)
WHERE "Rank" <= 5
ORDER BY "Year", "Rank";