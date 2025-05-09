/* -----------------------------------------------------------
   Top‑5 daily case jumps, Mar‑01–May‑31 2020
   1) Rank states by how many times they appear in the daily
      Top‑5 list.
   2) Take the state that ranks 4th overall, then rank its
      counties by how many times they appear in that state’s
      own daily Top‑5 list.
------------------------------------------------------------*/
WITH
/* ──────────────────────────────────────────────────────────
   STEP‑1 ─ Daily new‑case counts for every state
─────────────────────────────────────────────────────────── */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases)
          OVER (PARTITION BY state_name ORDER BY date) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ──────────────────────────────────────────────────────────
   STEP‑2 ─ The five states with the biggest jump each day
─────────────────────────────────────────────────────────── */
daily_state_top5 AS (
  SELECT date, state_name
  FROM (
    SELECT
      date,
      state_name,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
    FROM state_daily
  )
  WHERE rn <= 5
),

/* ──────────────────────────────────────────────────────────
   STEP‑3 ─ Count appearances & rank all states
─────────────────────────────────────────────────────────── */
state_rank AS (
  SELECT
    state_name,
    COUNT(*)                AS top5_count,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS overall_rank
  FROM daily_state_top5
  GROUP BY state_name
),

/* ──────────────────────────────────────────────────────────
   STEP‑4 ─ Identify the 4th‑ranked state
─────────────────────────────────────────────────────────── */
the_state AS (
  SELECT state_name
  FROM state_rank
  WHERE overall_rank = 4
),

/* ──────────────────────────────────────────────────────────
   STEP‑5 ─ Daily new‑case counts for every county
             in the 4th‑ranked state
─────────────────────────────────────────────────────────── */
county_daily AS (
  SELECT
    date,
    county,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases)
          OVER (PARTITION BY county_fips_code ORDER BY date) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
    AND state_name IN (SELECT state_name FROM the_state)
),

/* ──────────────────────────────────────────────────────────
   STEP‑6 ─ The five counties with the biggest jump
             in that state each day
─────────────────────────────────────────────────────────── */
daily_county_top5 AS (
  SELECT date, county
  FROM (
    SELECT
      date,
      county,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
    FROM county_daily
  )
  WHERE rn <= 5
),

/* ──────────────────────────────────────────────────────────
   STEP‑7 ─ Count appearances & take Top‑5 counties
─────────────────────────────────────────────────────────── */
county_rank AS (
  SELECT
    county,
    COUNT(*) AS top5_count
  FROM daily_county_top5
  GROUP BY county
  ORDER BY top5_count DESC
  LIMIT 5
)

/* ──────────────────────────────────────────────────────────
   FINAL OUTPUT ─ Combine the two rankings in one result set
─────────────────────────────────────────────────────────── */
SELECT
  'state_rank'                        AS section,
  state_name,
  top5_count                          AS appearances_in_daily_top5,
  overall_rank,
  CAST(NULL AS STRING)                AS county,
  CAST(NULL AS INT64)                 AS county_top5_count
FROM state_rank

UNION ALL

SELECT
  'county_rank'                       AS section,
  (SELECT state_name FROM the_state)  AS state_name,
  CAST(NULL AS INT64)                 AS appearances_in_daily_top5,
  CAST(NULL AS INT64)                 AS overall_rank,
  county,
  top5_count                          AS county_top5_count
FROM county_rank

ORDER BY
  section,
  COALESCE(overall_rank, 0),
  COALESCE(county_top5_count, 0) DESC,
  state_name,
  county;