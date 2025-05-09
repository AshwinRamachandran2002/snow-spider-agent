WITH ranked_venues AS (
  SELECT
    p.id,
    -- priority: journal > proceedings > book > book series
    COALESCE(
      NULLIF(p.journal.title, ''),
      NULLIF(p.proceedings_title.preferred, ''),
      NULLIF(p.book_title.preferred, ''),
      NULLIF(p.book_series_title.preferred, '')
    ) AS venue_title,
    grid_id
  FROM
    `bigquery-public-data.dimensions_ai_covid19.publications` AS p,
    UNNEST(p.research_orgs) AS grid_id
  WHERE
    p.date_inserted >= '2021-01-01'     -- from 2021 onwards
)
SELECT DISTINCT
  venue_title
FROM
  ranked_venues AS rv
JOIN
  `bigquery-public-data.dimensions_ai_covid19.grid` AS g
ON
  rv.grid_id = g.id
WHERE
  g.address.city = 'Qianjiang'          -- grid located in Qianjiang
  AND venue_title IS NOT NULL;