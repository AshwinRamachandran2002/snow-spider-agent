-- 1.  For each Continuum of Care (CoC) keep only 2015 and 2018 rows, 
--     sum Unsheltered_Homeless within every state–year pair
WITH yearly_state AS (
  SELECT
    UPPER(SUBSTR(`CoC_Number`, 0, 2)) AS state_abbr,
    `Count_Year`                                   AS yr,
    SUM(`Unsheltered_Homeless`)                    AS unsheltered
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state_abbr, yr
),

-- 2.  Pivot to have 2015 and 2018 side‑by‑side per state
state_pivot AS (
  SELECT
    state_abbr,
    MAX(CASE WHEN yr = 2015 THEN unsheltered END) AS u2015,
    MAX(CASE WHEN yr = 2018 THEN unsheltered END) AS u2018
  FROM yearly_state
  GROUP BY state_abbr
),

-- 3.  Percentage change (keep states having valid, non‑zero 2015 & 2018 counts)
state_change AS (
  SELECT
    state_abbr,
    u2015,
    u2018,
    SAFE_DIVIDE(u2018 - u2015, u2015) * 100 AS pct_change
  FROM state_pivot
  WHERE u2015 IS NOT NULL
    AND u2018 IS NOT NULL
    AND u2015 <> 0
),

-- 4.  National average of state percentage changes
national_avg AS (
  SELECT AVG(pct_change) AS avg_pct_change
  FROM state_change
),

-- 5.  Distance of each state’s change from the national average
state_diff AS (
  SELECT
    sc.state_abbr,
    sc.pct_change,
    nat.avg_pct_change,
    ABS(sc.pct_change - nat.avg_pct_change) AS abs_diff
  FROM state_change sc
  CROSS JOIN national_avg nat
)

-- 6.  Five states whose change is closest to the national average
SELECT state_abbr
FROM state_diff
ORDER BY abs_diff ASC
LIMIT 5;