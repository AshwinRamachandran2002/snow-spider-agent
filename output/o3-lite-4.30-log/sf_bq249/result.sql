SELECT
  CASE
    WHEN REGEXP_LIKE(f.value::STRING, '.*[ \t]+$') THEN 'trailing'
    WHEN REGEXP_LIKE(f.value::STRING, '^ ')         THEN 'Space'
    ELSE 'Other'
  END                          AS "line_type",
  COUNT(*)                     AS "total_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
     LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
WHERE c."binary" = FALSE
GROUP BY "line_type"
ORDER BY "line_type";