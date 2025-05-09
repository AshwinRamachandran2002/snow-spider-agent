/*--------------------------------------------------------------
  1)  Rank the states by how often they appear in the NATIONAL
      daily Top-5 list of new COVID-19 cases (01-Mar-2020 →
      31-May-2020).

  2)  Identify the state that finishes FOURTH in that ranking and
      find the five counties inside that state that most often
      appear in their own daily Top-5 list of new cases during
      the same period.

  The final result set contains both rankings and is identified
  by the “level” column:
        • level = 'state'                 → state-level ranking
        • level = 'county_in_4th_state'   → county-level ranking
----------------------------------------------------------------*/
WITH
/* ----------  State-level daily NEW cases  ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
        - LAG(confirmed_cases) OVER (PARTITION BY state_name
                                     ORDER BY date)      AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ----------  Per-day TOP-5 states  ---------- */
daily_top_states AS (
  SELECT
    date,
    state_name,
    RANK() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rnk
  FROM state_daily
  WHERE daily_new_cases IS NOT NULL
),

/* ----------  Overall state ranking  ---------- */
state_ranking AS (
  SELECT
    state_name                         AS name,
    COUNT(*)                           AS top5_appearances,
    1                                  AS ordering          -- keeps states first
  FROM daily_top_states
  WHERE rnk <= 5
  GROUP BY state_name
  ORDER BY top5_appearances DESC
),

/* ----------  Retrieve the 4th-ranked state  ---------- */
fourth_state AS (
  SELECT name AS state_name
  FROM state_ranking
  ORDER BY top5_appearances DESC
  LIMIT 1 OFFSET 3                     -- zero-based offset ⇒ 4th place
),

/* ----------  County-level daily NEW cases (inside 4th state) ---------- */
county_daily AS (
  SELECT
    c.date,
    c.county,
    c.state_name,
    c.confirmed_cases
        - LAG(c.confirmed_cases) OVER (PARTITION BY c.county ORDER BY c.date)
                                              AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` c
  JOIN fourth_state f
    ON c.state_name = f.state_name
  WHERE c.date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ----------  Per-day TOP-5 counties (inside 4th state) ---------- */
daily_top_counties AS (
  SELECT
    date,
    county,
    RANK() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rnk
  FROM county_daily
  WHERE daily_new_cases IS NOT NULL
),

/* ----------  County ranking (keep only Top-5 counties) ---------- */
county_ranking AS (
  SELECT
    county                          AS name,
    COUNT(*)                        AS top5_appearances,
    2                               AS ordering              -- keeps counties second
  FROM daily_top_counties
  WHERE rnk <= 5
  GROUP BY county
  ORDER BY top5_appearances DESC
  LIMIT 5
)

/* ----------  Combine both rankings in one tidy result set ---------- */
SELECT ordering, 'state'                  AS level, name, top5_appearances
FROM   state_ranking

UNION ALL

SELECT ordering, 'county_in_4th_state'    AS level, name, top5_appearances
FROM   county_ranking

ORDER BY ordering, top5_appearances DESC;