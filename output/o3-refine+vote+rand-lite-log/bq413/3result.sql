SELECT DISTINCT
  COALESCE(
      p.journal.title,
      p.proceedings_title.preferred,
      p.book_title.preferred,
      p.book_series_title.preferred
  ) AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
JOIN UNNEST(p.research_orgs) AS grid_id
JOIN `bigquery-public-data.dimensions_ai_covid19.grid` AS g
  ON g.id = grid_id
WHERE p.date_inserted >= TIMESTAMP('2021-01-01')
  AND LOWER(g.address.city) = 'qianjiang'
  AND COALESCE(
        p.journal.title,
        p.proceedings_title.preferred,
        p.book_title.preferred,
        p.book_series_title.preferred
      ) IS NOT NULL;