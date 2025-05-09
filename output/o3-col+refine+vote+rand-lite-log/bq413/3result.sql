WITH qianjiang_grids AS (
  SELECT id
  FROM `bigquery-public-data.dimensions_ai_covid19.grid`
  WHERE LOWER(address.city) = 'qianjiang'
),
qianjiang_pubs AS (
  SELECT
    COALESCE(
      p.journal.title,
      p.proceedings_title.preferred,
      p.book_title.preferred,
      p.book_series_title.preferred
    ) AS venue_title
  FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
  CROSS JOIN UNNEST(p.research_orgs) AS org_id
  JOIN qianjiang_grids q
    ON org_id = q.id
  WHERE p.date_inserted >= '2021-01-01'
)
SELECT DISTINCT
       venue_title
FROM   qianjiang_pubs
ORDER  BY venue_title;