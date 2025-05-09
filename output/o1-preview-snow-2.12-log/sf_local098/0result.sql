WITH actor_years AS (
    SELECT DISTINCT person."PID", person."Name", 
        TRY_TO_NUMBER(REGEXP_REPLACE(movie."year", '[^0-9]', '')) AS "year"
    FROM DB_IMDB.DB_IMDB.PERSON AS person
    JOIN DB_IMDB.DB_IMDB.M_CAST AS m_cast ON TRIM(person."PID") = TRIM(m_cast."PID")
    JOIN DB_IMDB.DB_IMDB.MOVIE AS movie ON m_cast."MID" = movie."MID"
    WHERE movie."year" IS NOT NULL AND movie."year" <> ''
),
actor_years_clean AS (
    SELECT "PID", "Name", "year"
    FROM actor_years
    WHERE "year" IS NOT NULL
),
actor_ordered_years AS (
    SELECT 
        "PID", "Name", "year",
        LEAD("year") OVER (PARTITION BY "PID" ORDER BY "year") AS "NextYear"
    FROM actor_years_clean 
),
actor_gaps AS (
    SELECT
        "PID", "Name", "year", "NextYear",
        "NextYear" - "year" AS "GapYears"
    FROM actor_ordered_years
),
max_gap_per_actor AS (
    SELECT "PID", "Name", MAX("GapYears") AS "MaxGap"
    FROM actor_gaps
    GROUP BY "PID", "Name"
),
actors_without_long_gap AS (
    SELECT "PID", "Name"
    FROM max_gap_per_actor
    WHERE "MaxGap" IS NULL OR "MaxGap" <=3
)

SELECT COUNT(*) AS "Number_of_actors_without_long_gap"
FROM actors_without_long_gap;