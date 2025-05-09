/*------------------------------------------------------------------------
  1)  Rank states by how often they land in the DAILY Top-5 for biggest
      COVID-19 case increases between 1 Mar 2020 and 31 May 2020.
  2)  Take the state that finishes 4-th in that ranking, then rank its
      counties by how often they appear in that state-level DAILY Top-5.
------------------------------------------------------------------------*/
WITH state_daily AS (                       -- daily new-case counts per state
    SELECT
        "date",
        "state_name",
        "confirmed_cases"
          - LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date")
          AS "new_cases"
    FROM COVID19_NYT.COVID19_NYT."US_STATES"
    WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
), state_ranks AS (                         -- rank states each day
    SELECT
        "date",
        "state_name",
        RANK() OVER (PARTITION BY "date" ORDER BY "new_cases" DESC) AS state_rank
    FROM state_daily
    WHERE "new_cases" IS NOT NULL
), state_top_counts AS (                    -- count Top-5 appearances
    SELECT
        "state_name",
        COUNT(*) AS top5_occurrences
    FROM state_ranks
    WHERE state_rank <= 5
    GROUP BY "state_name"
), state_ranked AS (                        -- give overall ranks
    SELECT
        "state_name",
        top5_occurrences,
        ROW_NUMBER() OVER (ORDER BY top5_occurrences DESC, "state_name") AS overall_rank
    FROM state_top_counts
), fourth_state AS (                        -- the 4-th ranked state
    SELECT "state_name" AS target_state
    FROM state_ranked
    WHERE overall_rank = 4
), county_daily AS (                        -- daily new-case counts per county in that state
    SELECT
        c."date",
        c."county",
        c."confirmed_cases"
          - LAG(c."confirmed_cases") OVER (PARTITION BY c."county" ORDER BY c."date")
          AS "new_cases"
    FROM COVID19_NYT.COVID19_NYT."US_COUNTIES" c
    WHERE c."state_name" = (SELECT target_state FROM fourth_state)
      AND c."date" BETWEEN '2020-03-01' AND '2020-05-31'
), county_ranks AS (                        -- rank counties each day within the state
    SELECT
        "date",
        "county",
        RANK() OVER (PARTITION BY "date" ORDER BY "new_cases" DESC) AS county_rank
    FROM county_daily
    WHERE "new_cases" IS NOT NULL
), county_top_counts AS (                   -- count county Top-5 appearances
    SELECT
        "county",
        COUNT(*) AS top5_occurrences
    FROM county_ranks
    WHERE county_rank <= 5
    GROUP BY "county"
), county_ranked AS (                       -- final county ranking
    SELECT
        "county",
        top5_occurrences,
        ROW_NUMBER() OVER (ORDER BY top5_occurrences DESC, "county") AS county_overall_rank
    FROM county_top_counts
)
-- Final output: first the state ranking, then the county ranking
SELECT
    'State Ranking (Mar–May 2020)' AS section,
    overall_rank                     AS rank,
    "state_name"                    AS name,
    top5_occurrences
FROM state_ranked

UNION ALL

SELECT
    'Top Counties in ' || (SELECT target_state FROM fourth_state) ||
    ' (Mar–May 2020)'   AS section,
    county_overall_rank AS rank,
    "county"            AS name,
    top5_occurrences
FROM county_ranked
WHERE county_overall_rank <= 5                -- keep only Top-5 counties
ORDER BY section, rank;