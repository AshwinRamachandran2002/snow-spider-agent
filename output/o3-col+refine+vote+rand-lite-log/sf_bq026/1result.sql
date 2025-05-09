WITH a61_pub AS (
    SELECT
        p."publication_number",
        p."country_code",
        FLOOR(p."publication_date" / 10000)            AS "pub_year",
        a.value:"name"::STRING                         AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc") c
         , LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'
), most_active_assignee AS (
    SELECT
        "assignee_name",
        COUNT(*)                                        AS "cnt",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC)      AS "rk"
    FROM a61_pub
    GROUP BY "assignee_name"
), busiest_year AS (
    SELECT
        a61_pub."assignee_name",
        a61_pub."pub_year",
        COUNT(*)                                        AS "cnt",
        ROW_NUMBER() OVER (PARTITION BY a61_pub."assignee_name"
                           ORDER BY COUNT(*) DESC)      AS "yr_rk"
    FROM a61_pub
    JOIN most_active_assignee m
      ON m."rk" = 1
     AND a61_pub."assignee_name" = m."assignee_name"
    GROUP BY a61_pub."assignee_name", a61_pub."pub_year"
), top_jurisdictions AS (
    SELECT
        a61_pub."country_code",
        COUNT(*)                                        AS "pubs_in_jurisdiction"
    FROM a61_pub
    JOIN busiest_year b
      ON b."yr_rk" = 1
     AND a61_pub."assignee_name" = b."assignee_name"
     AND a61_pub."pub_year"      = b."pub_year"
    GROUP BY a61_pub."country_code"
    ORDER BY "pubs_in_jurisdiction" DESC NULLS LAST
    LIMIT 5
)
SELECT
    LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY "pubs_in_jurisdiction" DESC NULLS LAST)
        AS "top5_jurisdictions"
FROM top_jurisdictions;