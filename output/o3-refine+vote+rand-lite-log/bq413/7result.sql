SELECT DISTINCT
  CASE
    WHEN p.journal.title IS NOT NULL                                  THEN p.journal.title
    WHEN p.proceedings_title.preferred IS NOT NULL                    THEN p.proceedings_title.preferred
    WHEN p.book_title.preferred IS NOT NULL                           THEN p.book_title.preferred
    ELSE                                                                p.book_series_title.preferred
  END AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS p
JOIN UNNEST(p.research_orgs) AS grid_id
JOIN `bigquery-public-data.dimensions_ai_covid19.grid` AS g
  ON g.id = grid_id
WHERE p.date_inserted >= TIMESTAMP('2021-01-01')
  AND g.address.city = 'Qianjiang'
  AND (
        p.journal.title IS NOT NULL
     OR p.proceedings_title.preferred IS NOT NULL
     OR p.book_title.preferred IS NOT NULL
     OR p.book_series_title.preferred IS NOT NULL
  );