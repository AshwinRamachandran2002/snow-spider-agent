WITH latest_meta AS (          -- newest release per package
    SELECT
        "name",
        "project_urls",
        ROW_NUMBER() OVER (PARTITION BY "name"
                           ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
latest_pkg AS (                -- keep only latest version per package
    SELECT "name","project_urls"
    FROM   latest_meta
    WHERE  rn = 1
),
raw_urls AS (                  -- explode project_urls & keep github links
    SELECT
        lp."name",
        CASE
             WHEN SPLIT_PART(TRIM(v.value::string),',',2) <> ''
                  THEN TRIM(SPLIT_PART(v.value::string,',',2))   -- text after “,”
             ELSE TRIM(v.value::string)
        END                                   AS raw_url
    FROM  latest_pkg lp,
          LATERAL FLATTEN(
              INPUT => COALESCE(TRY_PARSE_JSON(lp."project_urls"),
                                lp."project_urls")
          ) v
    WHERE LOWER(v.value::string) LIKE '%github.com%'
),
clean_urls AS (                -- strip paths like issues/…/tree and trailing “/”
    SELECT  "name",
            REGEXP_REPLACE(                               -- remove trailing paths
                REGEXP_REPLACE(raw_url,
                               '(/issues.*|/pull.*|/blob.*|/tree.*)$',
                               '',
                               1, 0, 'i'),
                '/$',''                                   -- remove trailing slash
            ) AS github_url
    FROM    raw_urls
),
dl_counts AS (                 -- total downloads per package
    SELECT LOWER("project") AS name_lower,
           COUNT(*)         AS downloads
    FROM   PYPI.PYPI.FILE_DOWNLOADS
    GROUP  BY LOWER("project")
),
one_url_per_pkg AS (           -- associate download counts with one url each
    SELECT
        d.downloads,
        c.github_url,
        ROW_NUMBER() OVER (PARTITION BY d.name_lower
                           ORDER BY c.github_url) AS rn
    FROM dl_counts d
    JOIN clean_urls c
      ON LOWER(c."name") = d.name_lower
),
top3 AS (                       -- get top 3 by downloads
    SELECT github_url
    FROM   one_url_per_pkg
    WHERE  rn = 1
    ORDER  BY downloads DESC NULLS LAST
    LIMIT  3
)
SELECT github_url
FROM   top3;