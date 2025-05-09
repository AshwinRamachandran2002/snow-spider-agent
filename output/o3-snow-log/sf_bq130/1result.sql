/* -----------------------------------------------------------
   1) Rank states by how often they appear in the DAILY top-5
      largest NEW-case increases between 1 Mar 2020 and 31 May 2020
   2) Identify the state that ranks 4-th in that list
   3) For that state, rank its counties by how often they appear
      in the DAILY top-5 county new-case list for the same period
   4) Return a combined result set:
        level  = 'state'  -> full state ranking
        level  = 'county' -> top-5 counties for the 4-th state
----------------------------------------------------------------*/
WITH state_daily AS (          -- daily new cases for every state
    SELECT
        "state_name",
        "date",
        "confirmed_cases",
        LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") AS prev_cases
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
), state_ranked AS (           -- rank states per day by new cases
    SELECT
        "date",
        "state_name",
        ("confirmed_cases" - COALESCE(prev_cases,0))            AS new_cases,
        ROW_NUMBER() OVER (PARTITION BY "date"
                           ORDER BY ("confirmed_cases" - COALESCE(prev_cases,0)) DESC NULLS LAST) AS rn
    FROM state_daily
), state_top5 AS (             -- keep daily top-5 states
    SELECT *
    FROM state_ranked
    WHERE rn <= 5
), state_frequency AS (        -- how often each state is in daily top-5
    SELECT
        "state_name",
        COUNT(*) AS top5_count
    FROM state_top5
    GROUP BY "state_name"
), state_frequency_ranked AS ( -- rank states by that frequency
    SELECT
        "state_name",
        top5_count,
        DENSE_RANK() OVER (ORDER BY top5_count DESC NULLS LAST) AS state_rank
    FROM state_frequency
), fourth_state AS (           -- the state(s) in 4-th place
    SELECT "state_name"
    FROM state_frequency_ranked
    WHERE state_rank = 4
), county_daily AS (           -- daily new cases for counties in the 4-th state
    SELECT
        "county",
        "state_name",
        "date",
        "confirmed_cases",
        LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date") AS prev_cases
    FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
    WHERE "state_name" IN (SELECT "state_name" FROM fourth_state)
      AND "date" BETWEEN '2020-03-01' AND '2020-05-31'
), county_ranked AS (          -- rank counties of that state per day
    SELECT
        "date",
        "county",
        ("confirmed_cases" - COALESCE(prev_cases,0))            AS new_cases,
        ROW_NUMBER() OVER (PARTITION BY "date"
                           ORDER BY ("confirmed_cases" - COALESCE(prev_cases,0)) DESC NULLS LAST) AS rn
    FROM county_daily
), county_top5 AS (            -- keep daily top-5 counties
    SELECT *
    FROM county_ranked
    WHERE rn <= 5
), county_frequency AS (       -- how often each county is in daily top-5
    SELECT
        "county",
        COUNT(*) AS top5_count
    FROM county_top5
    GROUP BY "county"
), county_top5_freq AS (       -- top-5 counties by that frequency
    SELECT
        "county",
        top5_count,
        ROW_NUMBER() OVER (ORDER BY top5_count DESC NULLS LAST) AS county_rank
    FROM county_frequency
    ORDER BY top5_count DESC NULLS LAST
    LIMIT 5
)
/* -----------------------------------------------------------
   FINAL OUTPUT
   -----------------------------------------------------------
   level | name (state or county) | top5_count | rank
----------------------------------------------------------------*/
SELECT
    'state'            AS level,
    "state_name"       AS name,
    top5_count,
    state_rank         AS rank
FROM state_frequency_ranked

UNION ALL

SELECT
    'county'           AS level,
    "county"           AS name,
    top5_count,
    county_rank        AS rank
FROM county_top5_freq

ORDER BY level, rank;