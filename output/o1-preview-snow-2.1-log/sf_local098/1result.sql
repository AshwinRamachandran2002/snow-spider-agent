WITH Actor_Years AS (
    SELECT
        "M_CAST"."PID",
        TRY_CAST(REGEXP_REPLACE("MOVIE"."year", '[^0-9]', '') AS INT) AS "Year"
    FROM
        DB_IMDB.DB_IMDB."M_CAST"
    JOIN
        DB_IMDB.DB_IMDB."MOVIE"
    ON
        "M_CAST"."MID" = "MOVIE"."MID"
    WHERE
        TRY_CAST(REGEXP_REPLACE("MOVIE"."year", '[^0-9]', '') AS INT) IS NOT NULL
    GROUP BY
        "M_CAST"."PID", "Year"
),
Actor_Gaps AS (
    SELECT
        "PID",
        "Year",
        LAG("Year") OVER (PARTITION BY "PID" ORDER BY "Year") AS "Prev_Year",
        ("Year" - LAG("Year") OVER (PARTITION BY "PID" ORDER BY "Year")) AS "Gap"
    FROM
        Actor_Years
),
Actor_Max_Gap AS (
    SELECT
        "PID",
        COALESCE(MAX("Gap"), 0) AS "Max_Gap"
    FROM
        Actor_Gaps
    GROUP BY
        "PID"
)
SELECT
    COUNT(DISTINCT "PID") AS "Number_of_actors_without_long_breaks"
FROM
    Actor_Max_Gap
WHERE
    "Max_Gap" <= 3;