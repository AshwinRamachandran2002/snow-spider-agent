WITH matched_publications AS (
  SELECT
    DISTINCT
    COALESCE(
      p.journal.title,
      p.proceedings_title.preferred,
      p.book_title.preferred,
      p.book_series_title.preferred
    ) AS venue_title
  FROM
    `bigquery-public-data.dimensions_ai_covid19.publications` AS p
    JOIN UNNEST(p.research_orgs) AS grid_id
    JOIN `bigquery-public-data.dimensions_ai_covid19.grid` AS g
      ON g.id = grid_id
  WHERE
    p.date_inserted >= '2021-01-01'
    AND g.address.city = 'Qianjiang'
)
SELECT
  venue_title
FROM
  matched_publications
WHERE
  venue_title IS NOT NULL;