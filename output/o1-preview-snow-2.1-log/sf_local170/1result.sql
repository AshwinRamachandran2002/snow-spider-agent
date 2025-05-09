WITH "FirstTerms" AS (
    SELECT
        l."id_bioguide",
        l."gender",
        t."state",
        TO_DATE(t."term_start", 'YYYY-MM-DD') AS "first_term_start"
    FROM
        "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS" l
    JOIN (
        SELECT
            t.*,
            ROW_NUMBER() OVER (PARTITION BY t."id_bioguide" ORDER BY TO_DATE(t."term_start", 'YYYY-MM-DD') ASC) AS rn
        FROM
            "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t
        WHERE
            t."term_start" IS NOT NULL AND t."term_start" != ''
    ) t ON l."id_bioguide" = t."id_bioguide" AND t.rn = 1
),
"Intervals" AS (
    SELECT 0 AS "interval_start" UNION ALL
    SELECT 2 UNION ALL
    SELECT 4 UNION ALL
    SELECT 6 UNION ALL
    SELECT 8 UNION ALL
    SELECT 10
),
"LegislatorIntervals" AS (
    SELECT
        ft."id_bioguide",
        ft."gender",
        ft."state",
        ft."first_term_start",
        i."interval_start",
        DATEADD('year', i."interval_start", ft."first_term_start") AS "interval_date"
    FROM
        "FirstTerms" ft
    CROSS JOIN
        "Intervals" i
),
"Coverage" AS (
    SELECT DISTINCT
        li."id_bioguide",
        li."gender",
        li."state",
        li."interval_start"
    FROM
        "LegislatorIntervals" li
    JOIN
        "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t
            ON li."id_bioguide" = t."id_bioguide"
    WHERE
        TO_DATE(t."term_start", 'YYYY-MM-DD') <= li."interval_date"
        AND TO_DATE(t."term_end", 'YYYY-MM-DD') >= li."interval_date"
),
"LegislatorsWithFullCoverage" AS (
    SELECT
        "id_bioguide",
        "gender",
        "state",
        COUNT(*) AS "intervals_covered"
    FROM
        "Coverage"
    GROUP BY
        "id_bioguide",
        "gender",
        "state"
    HAVING
        COUNT(*) = 6
),
"StatesWithBothGenders" AS (
    SELECT DISTINCT
        lwfc_m."state"
    FROM
        (SELECT DISTINCT "state" FROM "LegislatorsWithFullCoverage" WHERE "gender" = 'M') lwfc_m
    INNER JOIN
        (SELECT DISTINCT "state" FROM "LegislatorsWithFullCoverage" WHERE "gender" = 'F') lwfc_f
            ON lwfc_m."state" = lwfc_f."state"
)
SELECT
    "state" AS "State"
FROM
    "StatesWithBothGenders";