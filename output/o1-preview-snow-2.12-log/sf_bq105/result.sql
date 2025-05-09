WITH distractions AS (
    SELECT
        a."state_name",
        a."state_number",
        a."consecutive_number",
        2015 AS "year"
    FROM
        NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015 a
        JOIN NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2015 d
            ON a."state_number" = d."state_number" AND a."consecutive_number" = d."consecutive_number"
    WHERE
        d."driver_distracted_by_name" NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
    UNION ALL
    SELECT
        a."state_name",
        a."state_number",
        a."consecutive_number",
        2016 AS "year"
    FROM
        NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016 a
        JOIN NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2016 d
            ON a."state_number" = d."state_number" AND a."consecutive_number" = d."consecutive_number"
    WHERE
        d."driver_distracted_by_name" NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
),
state_distractions AS (
    SELECT
        "state_name",
        "year",
        COUNT(DISTINCT "consecutive_number") AS "distraction_accidents"
    FROM
        distractions
    GROUP BY
        "state_name",
        "year"
),
state_population AS (
    SELECT
        z."state_name",
        SUM(p."POPULATION") AS "population"
    FROM
        NHTSA_TRAFFIC_FATALITIES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010 p
        JOIN NHTSA_TRAFFIC_FATALITIES_PLUS.UTILITY_US.ZIPCODE_AREA z
            ON p."ZIPCODE" = z."zipcode"
    GROUP BY
        z."state_name"
),
state_rates AS (
    SELECT
        d."state_name",
        d."year",
        d."distraction_accidents",
        s."population",
        (d."distraction_accidents" / s."population") * 100000 AS "accidents_per_100k"
    FROM
        state_distractions d
        JOIN state_population s ON d."state_name" = s."state_name"
),
ranked_states AS (
    SELECT
        d."year",
        d."state_name",
        d."accidents_per_100k",
        ROW_NUMBER() OVER (PARTITION BY d."year" ORDER BY d."accidents_per_100k" DESC NULLS LAST) AS "rank"
    FROM
        state_rates d
)
SELECT
    "year" AS "Year",
    "state_name" AS "State",
    ROUND("accidents_per_100k", 4) AS "Accidents_per_100k"
FROM
    ranked_states
WHERE
    "rank" <= 5
ORDER BY
    "year",
    "Accidents_per_100k" DESC NULLS LAST;