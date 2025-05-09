/* ------------------------------------------------------------
   Daily-new-case “top-five” analysis, Mar–May 2020
   1.  Rank states by how often they appear in the nation-wide
       daily top-five list of new COVID-19 case increases.
   2.  Identify the state that places 4-th in that ranking and
       list its five counties that themselves appear most often
       in the nation-wide daily county top-five list.
-------------------------------------------------------------*/
WITH
/* ----------  STATE-LEVEL PART  ---------- */
state_daily AS (         -- daily new cases for every state
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date)
        AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_ranked AS (        -- rank states by new cases each day
  SELECT
    date,
    state_name,
    new_cases,
    DENSE_RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rk
  FROM state_daily
),
daily_state_top5 AS (    -- keep the five highest-increase states per day
  SELECT date, state_name
  FROM state_ranked
  WHERE rk <= 5
),
state_tally AS (         -- count how many times each state is in a daily top-five
  SELECT
    state_name,
    COUNT(*) AS appearances
  FROM daily_state_top5
  GROUP BY state_name
),
state_ranking AS (       -- overall ranking of those tallies
  SELECT
    state_name,
    appearances,
    DENSE_RANK() OVER (ORDER BY appearances DESC) AS overall_rank
  FROM state_tally
),

/* isolate the 4-th ranked state (could be >1 state if tied) */
fourth_state AS (
  SELECT state_name
  FROM state_ranking
  WHERE overall_rank = 4
),

/* ----------  COUNTY-LEVEL PART  ---------- */
county_daily AS (        -- daily new cases for every county
  SELECT
    date,
    county,
    state_name,
    county_fips_code,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY county_fips_code ORDER BY date)
        AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_ranked AS (       -- rank counties by new cases each day
  SELECT
    date,
    county,
    state_name,
    new_cases,
    DENSE_RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rk
  FROM county_daily
),
daily_county_top5 AS (   -- keep the five highest-increase counties per day
  SELECT date, county, state_name
  FROM county_ranked
  WHERE rk <= 5
),
county_filtered AS (     -- restrict to counties belonging to the 4-th ranked state(s)
  SELECT dc.county, dc.state_name
  FROM daily_county_top5 dc
  JOIN fourth_state fs
    USING (state_name)
),
county_tally AS (        -- count each county’s appearances in daily top-five
  SELECT
    county,
    state_name,
    COUNT(*) AS appearances
  FROM county_filtered
  GROUP BY county, state_name
),
county_ranking AS (      -- top five counties for that state
  SELECT
    county,
    state_name,
    appearances,
    ROW_NUMBER() OVER (ORDER BY appearances DESC) AS county_rank
  FROM county_tally
  ORDER BY county_rank
  LIMIT 5
)

/* ----------  FINAL OUTPUT  ---------- */
SELECT
  'STATE_RANKING'                            AS section,
  state_name,
  NULL                                       AS county,
  appearances,
  overall_rank                               AS rank
FROM state_ranking

UNION ALL

SELECT
  'TOP_COUNTIES_OF_4TH_STATE'                AS section,
  state_name,
  county,
  appearances,
  county_rank                                AS rank
FROM county_ranking

ORDER BY section, rank;