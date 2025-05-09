WITH latest_pkg AS (   -- most recent version of every package
    SELECT
        "name",
        "project_urls",
        ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
latest_project_urls AS (  -- keep only latest rows
    SELECT
        "name",
        TRY_PARSE_JSON("project_urls")                 AS prj_urls_json
    FROM latest_pkg
    WHERE rn = 1
),
urls_expanded AS (       -- explode every URL found in project_urls
    SELECT
        l."name",
        f.value::STRING                                AS raw_url
    FROM latest_project_urls l,
         LATERAL FLATTEN(input => prj_urls_json) f
    WHERE f.value::STRING ILIKE '%github.com%'         -- keep only GitHub links
),
clean_urls AS (          -- strip down to repository root
    SELECT
        "name",
        REGEXP_REPLACE(                                -- remove trailing paths like issues/, pull/, blob/, tree/
            REGEXP_REPLACE(
                RTRIM(SPLIT_PART(raw_url, '#', 1), '/'),   -- drop URL fragment & trailing slash
                '(\\/issues.*|\\/pull.*|\\/blob.*|\\/tree.*)$',
                ''
            ),
            '\\.git$',
            ''
        )                                              AS repo_url
    FROM urls_expanded
),
download_counts AS (     -- total download count per package
    SELECT
        "project"                                        AS name,
        COUNT(*)                                         AS dl_cnt
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
ranked_repos AS (
    SELECT
        DISTINCT c.repo_url,
        d.dl_cnt,
        ROW_NUMBER() OVER (ORDER BY d.dl_cnt DESC NULLS LAST, c.repo_url) AS rnk
    FROM clean_urls   c
    JOIN download_counts d
      ON c."name" = d.name
)
SELECT repo_url
FROM ranked_repos
WHERE rnk <= 3;