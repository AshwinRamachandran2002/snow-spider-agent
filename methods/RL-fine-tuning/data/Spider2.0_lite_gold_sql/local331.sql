WITH ordered_log AS (
  SELECT
    session,
    stamp,
    RTRIM(path, '/') AS norm_path,
    ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp) AS rn
  FROM activity_log
)
SELECT
  t3.norm_path AS Third_page_url,
  COUNT(*) AS Count
FROM ordered_log t1
JOIN ordered_log t2 ON t1.session = t2.session AND t2.rn = t1.rn + 1
JOIN ordered_log t3 ON t2.session = t3.session AND t3.rn = t2.rn + 1
WHERE t1.norm_path = '/detail' AND t2.norm_path = '/detail' AND t3.norm_path != ''
GROUP BY t3.norm_path
ORDER BY Count DESC
LIMIT 3;