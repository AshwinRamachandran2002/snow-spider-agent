/* Top-5 most frequently used Python (import/from) and R (library) modules */
SELECT   "module",
         SUM("cnt") AS "total_cnt"
FROM   (
        /* ---------- Python: `import` & `from` ---------- */
        SELECT LOWER(pymod) AS "module", COUNT(*) AS "cnt"
        FROM (
              /* `import xxx` */
              SELECT REGEXP_SUBSTR(line.value::STRING,
                                   '\\bimport\\s+([A-Za-z0-9_\\.]+)',
                                   1, 1, 'e', 1) AS pymod
              FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
                   LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
              WHERE sc."sample_path" ILIKE '%.py'
                AND line.value ILIKE 'import %'

              UNION ALL

              /* `from xxx import` */
              SELECT REGEXP_SUBSTR(line.value::STRING,
                                   '\\bfrom\\s+([A-Za-z0-9_\\.]+)',
                                   1, 1, 'e', 1) AS pymod
              FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
                   LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
              WHERE sc."sample_path" ILIKE '%.py'
                AND line.value ILIKE 'from %'
             ) py
        WHERE pymod IS NOT NULL
        GROUP BY LOWER(pymod)

        UNION ALL

        /* ---------- R: `library()` ---------- */
        SELECT LOWER(rmod) AS "module", COUNT(*) AS "cnt"
        FROM (
              SELECT REGEXP_SUBSTR(line.value::STRING,
                                   'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                                   1, 1, 'e', 1) AS rmod
              FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
                   LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
              WHERE sc."sample_path" ILIKE '%.r'
                AND line.value ILIKE 'library(%'
             ) r
        WHERE rmod IS NOT NULL
        GROUP BY LOWER(rmod)
      ) all_mods
GROUP BY "module"
ORDER BY "total_cnt" DESC NULLS LAST
LIMIT 5;