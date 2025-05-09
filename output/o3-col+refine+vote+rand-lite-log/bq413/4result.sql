-- Venue titles of publications (2021-present) linked to any GRID organisation located in Qianjiang.
SELECT DISTINCT
  COALESCE(
    p.journal.title,
    p.proceedings_title.preferred,
    p.book_title.preferred,
    p.book_series_title.preferred
  ) AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
JOIN UNNEST(p.research_orgs) AS org
JOIN (
  SELECT id
  FROM `bigquery-public-data.dimensions_ai_covid19.grid`
  WHERE LOWER(address.city) = 'qianjiang'
) AS g
ON org = g.id
WHERE p.date_inserted >= '2021-01-01'
  AND COALESCE(
        p.journal.title,
        p.proceedings_title.preferred,
        p.book_title.preferred,
        p.book_series_title.preferred
      ) IS NOT NULL;