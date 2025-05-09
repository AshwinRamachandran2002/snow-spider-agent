WITH
-- 1. Find the five most frequent minor crime categories in 2008
top5 AS (
  SELECT
    minor_category,
    SUM(value) AS tot_2008
  FROM
    `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE
    year = 2008
  GROUP BY
    minor_category
  ORDER BY
    tot_2008 DESC
  LIMIT 5
),

-- 2. Store those five categories in a fixed‑order array
top5_arr AS (
  SELECT
    ARRAY_AGG(minor_category ORDER BY tot_2008 DESC) AS cats
  FROM
    top5
),

-- 3. Yearly totals for the whole of London
year_tot AS (
  SELECT
    year,
    SUM(value) AS tot_crimes
  FROM
    `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY
    year
),

-- 4. Yearly totals for each of the top‑5 minor categories
cat_year_tot AS (
  SELECT
    year,
    minor_category,
    SUM(value) AS cat_crimes
  FROM
    `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE
    minor_category IN (SELECT minor_category FROM top5)
  GROUP BY
    year,
    minor_category
),

-- 5. Convert those totals to percentage shares of the annual total
shares AS (
  SELECT
    c.year,
    c.minor_category,
    ROUND(100 * c.cat_crimes / y.tot_crimes , 2) AS pct_share
  FROM
    cat_year_tot   AS c
    JOIN year_tot  AS y  USING (year)
)

-- 6. Pivot the five categories so that each year is one row
SELECT
  s.year,

  cats[OFFSET(0)] AS category1,
  ROUND(SUM(CASE WHEN s.minor_category = cats[OFFSET(0)] THEN s.pct_share END), 2) AS category1_pct,

  cats[OFFSET(1)] AS category2,
  ROUND(SUM(CASE WHEN s.minor_category = cats[OFFSET(1)] THEN s.pct_share END), 2) AS category2_pct,

  cats[OFFSET(2)] AS category3,
  ROUND(SUM(CASE WHEN s.minor_category = cats[OFFSET(2)] THEN s.pct_share END), 2) AS category3_pct,

  cats[OFFSET(3)] AS category4,
  ROUND(SUM(CASE WHEN s.minor_category = cats[OFFSET(3)] THEN s.pct_share END), 2) AS category4_pct,

  cats[OFFSET(4)] AS category5,
  ROUND(SUM(CASE WHEN s.minor_category = cats[OFFSET(4)] THEN s.pct_share END), 2) AS category5_pct

FROM
  shares            AS s
  CROSS JOIN top5_arr  -- gives access to the ordered array “cats”
GROUP BY
  s.year, cats
ORDER BY
  s.year;