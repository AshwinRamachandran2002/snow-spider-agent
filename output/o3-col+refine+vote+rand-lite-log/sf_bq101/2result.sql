SELECT
  pkg                         AS "java_package",
  COUNT(*)                    AS "times_imported"
FROM (
  SELECT
    REGEXP_REPLACE(
      REGEXP_SUBSTR(
        TRIM(line.value::STRING),
        'import\\s+([A-Za-z0-9_\\.]+)',
        1, 1, 'e', 1
      ),
      '\\.[^.]*$',
      ''
    )                         AS pkg
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     AS f
  JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  AS c
    ON f."id" = c."id"
  , LATERAL SPLIT_TO_TABLE(c."content", '\n')           AS line
  WHERE f."path" ILIKE '%.java'
    AND line.value ILIKE 'import %'
)
GROUP BY pkg
ORDER BY "times_imported" DESC NULLS LAST
LIMIT 10;