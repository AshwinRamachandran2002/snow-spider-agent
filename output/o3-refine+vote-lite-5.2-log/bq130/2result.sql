/* --------------------------------------------------------------------
   1)  Find, for every day from 2020‑03‑01 through 2020‑05‑31, the five
       states with the largest DAILY increase in confirmed cases.
   2)  Rank states by how many times they appear in those daily “Top‑5”
       lists and keep the overall Top‑5 states.
   3)  Take the state that ranks FOURTH in that list and, for the same
       date range, determine which of its counties most often land in
       the nationwide daily county “Top‑5” for new cases.
   4)  Return one result set that shows
          • the Top‑5 states with their appearance counts and ranks
          • the Top‑5 counties (within the 4th‑ranked state) with the
            same information.
---------------------------------------------------------------------*/
WITH
/* ----------  State‑level daily NEW cases  ------------------------- */
state_daily AS (
  SELECT
    date,
    state_name,
    IFNULL(confirmed_cases
           - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date),
           confirmed_cases) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ----------  Daily Top‑5 States  ---------------------------------- */
daily_top_states AS (
  SELECT date, state_name, new_cases
  FROM (
    SELECT
      date,
      state_name,
      new_cases,
      ROW_NUMBER() OVER (PARTITION BY date
                         ORDER BY new_cases DESC, state_name) AS rn
    FROM state_daily
  )
  WHERE rn <= 5
),

/* ----------  How often does each state appear? -------------------- */
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS appearance_count,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC, state_name) AS state_rank
  FROM daily_top_states
  GROUP BY state_name
),

/* ----------  Keep only the overall Top‑5 states ------------------- */
top5_states AS (
  SELECT state_name, appearance_count, state_rank
  FROM state_frequency
  WHERE state_rank <= 5
),

/* ----------  Identify the 4th‑ranked state ------------------------ */
target_state AS (
  SELECT state_name
  FROM state_frequency
  WHERE state_rank = 4
  LIMIT 1
),

/* ----------  County‑level daily NEW cases ------------------------- */
county_daily AS (
  SELECT
    date,
    state_name,
    county,
    county_fips_code,
    IFNULL(confirmed_cases
           - LAG(confirmed_cases) OVER (PARTITION BY county_fips_code ORDER BY date),
           confirmed_cases) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ----------  Daily nationwide Top‑5 counties ---------------------- */
daily_top_counties AS (
  SELECT date, state_name, county, new_cases
  FROM (
    SELECT
      date,
      state_name,
      county,
      new_cases,
      ROW_NUMBER() OVER (PARTITION BY date
                         ORDER BY new_cases DESC, county) AS rn
    FROM county_daily
  )
  WHERE rn <= 5
),

/* ----------  Frequency for counties in the 4th state -------------- */
county_frequency AS (
  SELECT
    county,
    state_name,
    COUNT(*) AS appearance_count,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC, county) AS county_rank
  FROM daily_top_counties
  WHERE state_name = (SELECT state_name FROM target_state)
  GROUP BY county, state_name
  ORDER BY county_rank
  LIMIT 5
),

/* ----------  Assemble final output -------------------------------- */
final_states AS (
  SELECT
    'State'        AS level,
    state_name     AS name,
    appearance_count,
    state_rank     AS rank
  FROM top5_states
),
final_counties AS (
  SELECT
    'County'                                 AS level,
    CONCAT(county, ', ', state_name)         AS name,
    appearance_count,
    county_rank                              AS rank
  FROM county_frequency
)

SELECT * FROM final_states
UNION ALL
SELECT * FROM final_counties
ORDER BY level, rank;