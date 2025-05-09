WITH --------------------------------------------------------------------
-- 1.  DAILY NEW CASES FOR EACH STATE  -----------------------------------
state_daily AS (
  SELECT
    date,
    state_name,
    COALESCE(confirmed_cases 
             - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date),
             confirmed_cases)                AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

-- 2.  RANK STATES EACH DAY BY NEW CASES ---------------------------------
state_rank_each_day AS (
  SELECT
    date,
    state_name,
    new_cases,
    RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS daily_rank
  FROM state_daily
),

-- 3.  COUNT HOW OFTEN EACH STATE IS IN THE DAILY TOP‑5 ------------------
state_ranking AS (
  SELECT
    state_name,
    COUNTIF(daily_rank <= 5)                      AS appearances,
    RANK()  OVER (ORDER BY COUNTIF(daily_rank <= 5) DESC, state_name) 
                                                 AS overall_rank
  FROM state_rank_each_day
  GROUP BY state_name
),

-- 4.  THE STATE THAT RANKS 4th OVERALL ----------------------------------
fourth_state AS (
  SELECT state_name
  FROM state_ranking
  WHERE overall_rank = 4
),

---------------------------------------------------------------------------
-- 5.  DAILY NEW CASES FOR EVERY COUNTY -----------------------------------
county_daily AS (
  SELECT
    c.date,
    c.state_name,
    c.county,
    COALESCE(c.confirmed_cases
             - LAG(c.confirmed_cases) OVER (PARTITION BY c.state_name, c.county ORDER BY c.date),
             c.confirmed_cases)                 AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  WHERE c.date BETWEEN '2020-03-01' AND '2020-05-31'
),

-- 6.  RANK ALL COUNTIES NATIONWIDE EACH DAY -----------------------------
county_rank_each_day AS (
  SELECT
    date,
    state_name,
    county,
    new_cases,
    RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS daily_rank
  FROM county_daily
),

-- 7.  COUNT HOW OFTEN EACH COUNTY (OF THE 4th STATE) IS IN THE DAILY TOP‑5
county_ranking AS (
  SELECT
    cr.county,
    cr.state_name,
    COUNTIF(cr.daily_rank <= 5) AS appearances
  FROM   county_rank_each_day  AS cr
  JOIN   fourth_state          AS fs
  ON     cr.state_name = fs.state_name
  GROUP  BY county, state_name
)

---------------------------------------------------------------------------
-- 8.  COMBINE RESULTS:  (a) STATE RANKING, (b) TOP‑5 COUNTIES OF 4th STATE
SELECT
  'state'           AS level,
  state_name        AS name,
  appearances,
  overall_rank      AS rank
FROM state_ranking

UNION ALL

SELECT
  CONCAT('county_of_', (SELECT state_name FROM fourth_state))  AS level,
  county                                                  AS name,
  appearances,
  ROW_NUMBER() OVER (ORDER BY appearances DESC, county)   AS rank
FROM county_ranking
QUALIFY rank <= 5

ORDER BY level, rank;