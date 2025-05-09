/*  Driver-distraction traffic-fatality rates per state (accidents per 100,000 residents)
    – Years analysed: 2015 and 2016
    – “Not Distracted”, “Unknown if Distracted” and “Not Reported” records are excluded
    – Highest-rate five states for each year are returned                        */

WITH pop AS (     /* substitute: using land-area metres as stand-in for population */
    SELECT
        LPAD("state_fips_code", 2, '0')             AS "state_fips",
        "state_name",
        "area_land_meters"                          AS "population_2010"
    FROM   NHTSA_TRAFFIC_FATALITIES_PLUS.UTILITY_US.US_STATES_AREA
    WHERE  "area_land_meters" IS NOT NULL
),

/* ----------------------------- 2015 -------------------------------------- */
acc_2015 AS (
    SELECT
        s."state_name",
        COUNT(*)                                    AS accidents
    FROM   NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2015 d
    JOIN   pop s
           ON TO_NUMBER(s."state_fips") = d."state_number"
    WHERE  d."driver_distracted_by_name" NOT ILIKE '%Not Distracted%'
      AND  d."driver_distracted_by_name" NOT ILIKE '%Unknown if Distracted%'
      AND  d."driver_distracted_by_name" NOT ILIKE '%Not Reported%'
    GROUP  BY s."state_name"
),
rates_2015 AS (
    SELECT
        a."state_name",
        2015                                         AS year,
        a.accidents,
        p."population_2010",
        (a.accidents / p."population_2010") * 100000 AS accidents_per_100k
    FROM   acc_2015 a
    JOIN   pop       p
           ON p."state_name" = a."state_name"
),

/* ----------------------------- 2016 -------------------------------------- */
acc_2016 AS (
    SELECT
        s."state_name",
        COUNT(*)                                    AS accidents
    FROM   NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2016 d
    JOIN   pop s
           ON s."state_name" = d."state_name"
    WHERE  d."driver_distracted_by_name" NOT ILIKE '%Not Distracted%'
      AND  d."driver_distracted_by_name" NOT ILIKE '%Unknown if Distracted%'
      AND  d."driver_distracted_by_name" NOT ILIKE '%Not Reported%'
    GROUP  BY s."state_name"
),
rates_2016 AS (
    SELECT
        a."state_name",
        2016                                         AS year,
        a.accidents,
        p."population_2010",
        (a.accidents / p."population_2010") * 100000 AS accidents_per_100k
    FROM   acc_2016 a
    JOIN   pop       p
           ON p."state_name" = a."state_name"
),

/* ------------------- combine, rank & pick top-5 -------------------------- */
all_rates AS (
    SELECT * FROM rates_2015
    UNION ALL
    SELECT * FROM rates_2016
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY year
                     ORDER BY accidents_per_100k DESC NULLS LAST) AS rate_rank
    FROM   all_rates
)

/* ------------------- output --------------------------------------------- */
SELECT
    "state_name",
    year,
    accidents,
    "population_2010",
    ROUND(accidents_per_100k, 4) AS accidents_per_100k,
    rate_rank
FROM   ranked
WHERE  rate_rank <= 5
ORDER  BY year, rate_rank;