-- Venue titles (journal ▸ proceedings ▸ book ▸ series) for Qianjiang-linked publications inserted from 2021 onward
SELECT DISTINCT
  COALESCE(p.journal.title,
           p.proceedings_title.preferred,
           p.book_title.preferred,
           p.book_series_title.preferred) AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
JOIN UNNEST(p.research_orgs) AS org_id
JOIN `bigquery-public-data.dimensions_ai_covid19.grid` AS g
  ON g.id = org_id
WHERE p.date_inserted >= '2021-01-01'
  AND LOWER(g.address.city) = 'qianjiang';