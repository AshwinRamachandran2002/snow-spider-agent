-- Venue titles for publications (inserted in 2021 or later) linked to any GRID
-- organisation whose address city is 'Qianjiang'.  Priority order:
-- journal → proceedings → book → book-series.
SELECT DISTINCT
  COALESCE(p.journal.title,
           p.proceedings_title.preferred,
           p.book_title.preferred,
           p.book_series_title.preferred) AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
JOIN UNNEST(p.research_orgs) AS grid_id
ON TRUE
JOIN `bigquery-public-data.dimensions_ai_covid19.grid` AS g
  ON g.id = grid_id
WHERE LOWER(g.address.city) = 'qianjiang'
  AND p.date_inserted >= '2021-01-01'
  AND COALESCE(p.journal.title,
               p.proceedings_title.preferred,
               p.book_title.preferred,
               p.book_series_title.preferred) IS NOT NULL;