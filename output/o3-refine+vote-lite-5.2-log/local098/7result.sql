WITH appearances AS (
    -- every (actor,year) in which the actor appeared, years made integer and deduplicated
    SELECT DISTINCT
        mc."PID"                    AS actor_id,
        CAST(m."year" AS INTEGER)   AS yr
    FROM "M_Cast"  mc
    JOIN "Movie"   m  ON m."MID" = mc."MID"
),
ordered AS (
    -- order the years for every actor and look at the previous credited year
    SELECT
        actor_id,
        yr,
        LAG(yr) OVER (PARTITION BY actor_id ORDER BY yr) AS prev_yr
    FROM appearances
),
bad_actors AS (
    -- an actor is “bad” if any gap of at least 4 empty years exists, i.e. a difference > 4
    SELECT DISTINCT actor_id
    FROM ordered
    WHERE prev_yr IS NOT NULL
      AND (yr - prev_yr) > 4
)
SELECT COUNT(DISTINCT actor_id) AS actors_without_long_gaps
FROM appearances
WHERE actor_id NOT IN (SELECT actor_id FROM bad_actors);