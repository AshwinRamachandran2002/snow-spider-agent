WITH avg_anosmia AS (
    SELECT
        AVG(CASE WHEN TO_DATE("date", 'YYYY-MM-DD') BETWEEN '2019-01-01' AND '2019-12-31' THEN CAST("symptom_anosmia" AS FLOAT) END) AS "avg_2019",
        AVG(CASE WHEN TO_DATE("date", 'YYYY-MM-DD') BETWEEN '2020-01-01' AND '2020-12-31' THEN CAST("symptom_anosmia" AS FLOAT) END) AS "avg_2020"
    FROM
        COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_SUB_REGION_2_WEEKLY
    WHERE
        "sub_region_2" IN ('Bronx County', 'Queens County', 'Kings County', 'New York County', 'Richmond County')
)
SELECT
    ROUND((("avg_2020" - "avg_2019") / "avg_2019") * 100, 4) AS "percentage_change"
FROM
    avg_anosmia;