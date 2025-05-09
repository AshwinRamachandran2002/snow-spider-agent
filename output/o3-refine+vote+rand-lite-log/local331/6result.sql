WITH ordered AS (
  SELECT
    session,
    path,
    ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp) AS rn
  FROM activity_log
  WHERE path IS NOT NULL
),
triples AS (
  /* pick records where two consecutive '/detail' visits
     are immediately followed by a third page */
  SELECT
    c.path AS third_page
  FROM ordered a
  JOIN ordered b
        ON b.session = a.session
       AND b.rn     = a.rn + 1
  JOIN ordered c
        ON c.session = a.session
       AND c.rn     = a.rn + 2
  WHERE a.path LIKE '/detail%'
    AND b.path LIKE '/detail%'
)
SELECT
  third_page         AS "page",
  COUNT(*)           AS "occurrences"
FROM triples
GROUP BY third_page
ORDER BY occurrences DESC, page
LIMIT 3;