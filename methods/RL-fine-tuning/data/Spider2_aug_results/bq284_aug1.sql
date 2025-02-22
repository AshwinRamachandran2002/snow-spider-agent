-- Task: Can you provide the total number of articles in each category and the total number of articles that mention "education" within each category from the BBC News?
SELECT 
  category,
  COUNT(*) AS number_total_by_category,
  SUM(CASE WHEN LOWER(body) LIKE '%education%' THEN 1 ELSE 0 END) AS number_with_education
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY category;