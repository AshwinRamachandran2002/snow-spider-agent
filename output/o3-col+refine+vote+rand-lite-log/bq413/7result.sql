-- Venue titles of publications (inserted ≥ 2021) linked to any GRID organisation
-- whose address.city is “Qianjiang”.  Title priority: journal ▸ proceedings ▸ book ▸ series.
WITH qianjiang_grids AS (
  SELECT id
  FROM `bigquery-public-data.dimensions_ai_covid19.grid`
  WHERE LOWER(address.city) = 'qianjiang'
)

SELECT DISTINCT
  COALESCE(
    NULLIF(p.journal.title, ''),
    NULLIF(p.proceedings_title.preferred, ''),
    NULLIF(p.book_title.preferred, ''),
    NULLIF(p.book_series_title.preferred, '')
  ) AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
CROSS JOIN UNNEST(p.research_orgs) AS org_id
JOIN qianjiang_grids q
  ON org_id = q.id
WHERE p.date_inserted >= '2021-01-01'
  AND COALESCE(
        NULLIF(p.journal.title, ''),
        NULLIF(p.proceedings_title.preferred, ''),
        NULLIF(p.book_title.preferred, ''),
        NULLIF(p.book_series_title.preferred, '')
      ) IS NOT NULL;