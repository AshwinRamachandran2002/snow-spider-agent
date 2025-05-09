-- Fixed version: use an explicit JOIN instead of a correlated sub-query
WITH qianjiang_grids AS (
  SELECT id
  FROM `bigquery-public-data.dimensions_ai_covid19.grid`
  WHERE LOWER(`address`.city) = 'qianjiang'
),

pubs_with_qianjiang AS (
  SELECT DISTINCT
    p.id,
    COALESCE(
      p.journal.title,
      p.proceedings_title.preferred,
      p.book_title.preferred,
      p.book_series_title.preferred
    ) AS venue_title
  FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
  -- explode research_orgs and match to Qianjiang GRID ids
  CROSS JOIN UNNEST(p.research_orgs) AS grid_id
  JOIN qianjiang_grids q
    ON grid_id = q.id
  WHERE p.date_inserted >= '2021-01-01'
)

SELECT DISTINCT
  venue_title
FROM pubs_with_qianjiang
WHERE venue_title IS NOT NULL;