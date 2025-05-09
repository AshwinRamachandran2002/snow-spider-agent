SELECT COUNT(DISTINCT f1.session) AS sessions_with_regist_flow
FROM form_log AS f1
JOIN form_log AS f2
  ON f1.session = f2.session
WHERE f1.path = '/regist/input'
  AND f2.path = '/regist/confirm'
  AND f1.stamp < f2.stamp;