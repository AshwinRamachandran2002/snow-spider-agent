-- venue titles for publications (2021‑present) linked to organisations in Qianjiang
WITH qianjiang_orgs AS (
  SELECT id AS grid_id
  FROM `bigquery-public-data.dimensions_ai_covid19.grid`
  WHERE LOWER(address.city) = 'qianjiang'
)

SELECT DISTINCT
  p.id AS publication_id,
  COALESCE(
    p.journal.title,
    p.proceedings_title.preferred,
    p.book_title.preferred,
    p.book_series_title.preferred
  ) AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
JOIN qianjiang_orgs q
ON q.grid_id IN UNNEST(p.research_orgs)
WHERE DATE(p.date_inserted) >= '2021-01-01';