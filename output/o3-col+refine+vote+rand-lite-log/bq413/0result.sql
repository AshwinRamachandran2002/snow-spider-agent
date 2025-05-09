-- Venue titles of publications (2021-present) linked to Qianjiang-based GRID records
WITH qianjiang_grids AS (
  SELECT id
  FROM `bigquery-public-data.dimensions_ai_covid19.grid`
  WHERE LOWER(address.city) = 'qianjiang'          -- city match
),
filtered_pubs AS (
  SELECT p.*
  FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
  JOIN qianjiang_grids q
    ON q.id IN UNNEST(p.research_orgs)             -- association via research orgs
    OR q.id IN UNNEST(p.funder_orgs)               -- … or via funders
  WHERE DATE(p.date_inserted) >= '2021-01-01'      -- inserted in 2021 or later
)
SELECT DISTINCT
  COALESCE(
    p.journal.title,
    p.proceedings_title.preferred,
    p.book_title.preferred,
    p.book_series_title.preferred
  ) AS venue_title
FROM filtered_pubs AS p
WHERE COALESCE(
        p.journal.title,
        p.proceedings_title.preferred,
        p.book_title.preferred,
        p.book_series_title.preferred
      ) IS NOT NULL
ORDER BY venue_title;