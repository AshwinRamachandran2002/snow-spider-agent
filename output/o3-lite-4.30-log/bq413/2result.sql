SELECT DISTINCT
  COALESCE(
    pub.journal.title,
    pub.proceedings_title.preferred,
    pub.book_title.preferred,
    pub.book_series_title.preferred
  ) AS venue_title
FROM `bigquery-public-data.dimensions_ai_covid19.publications` AS pub
CROSS JOIN UNNEST(pub.research_orgs) AS research_org_id
JOIN `bigquery-public-data.dimensions_ai_covid19.grid` AS g
  ON g.id = research_org_id
WHERE LOWER(g.address.city) = 'qianjiang'
  AND DATE(pub.date_inserted) >= '2021-01-01';