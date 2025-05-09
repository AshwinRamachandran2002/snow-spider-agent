WITH ordered AS (
  SELECT
      session,
      path,
      stamp,
      LAG(path,1) OVER (PARTITION BY session ORDER BY stamp) AS prev1,
      LAG(path,2) OVER (PARTITION BY session ORDER BY stamp) AS prev2
  FROM "activity_log"
  WHERE action = 'view'
),
third_page_candidates AS (
  SELECT path AS third_page
  FROM ordered
  WHERE prev1 = '/detail'
    AND prev2 = '/detail'
    AND path IS NOT NULL
)
SELECT
    third_page,
    COUNT(*) AS visit_count
FROM third_page_candidates
GROUP BY third_page
ORDER BY visit_count DESC, third_page
LIMIT 3;