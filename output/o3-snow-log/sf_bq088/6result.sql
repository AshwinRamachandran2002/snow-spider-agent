SELECT
    /* --------------- 2019 averages --------------- */
    AVG(
        CASE 
            WHEN TO_DATE("date") >= '2019-01-01'
             AND TO_DATE("date") <  '2020-01-01'
            THEN TRY_CAST("symptom_anxiety"    AS FLOAT)
        END
    )                                                   AS "avg_anxiety_2019",
    AVG(
        CASE 
            WHEN TO_DATE("date") >= '2019-01-01'
             AND TO_DATE("date") <  '2020-01-01'
            THEN TRY_CAST("symptom_depression" AS FLOAT)
        END
    )                                                   AS "avg_depression_2019",

    /* --------------- 2020 averages --------------- */
    AVG(
        CASE 
            WHEN TO_DATE("date") >= '2020-01-01'
             AND TO_DATE("date") <  '2021-01-01'
            THEN TRY_CAST("symptom_anxiety"    AS FLOAT)
        END
    )                                                   AS "avg_anxiety_2020",
    AVG(
        CASE 
            WHEN TO_DATE("date") >= '2020-01-01'
             AND TO_DATE("date") <  '2021-01-01'
            THEN TRY_CAST("symptom_depression" AS FLOAT)
        END
    )                                                   AS "avg_depression_2020",

    /* --------------- % increase from 2019 to 2020 --------------- */
    (
        AVG(
            CASE 
                WHEN TO_DATE("date") >= '2020-01-01'
                 AND TO_DATE("date") <  '2021-01-01'
                THEN TRY_CAST("symptom_anxiety" AS FLOAT)
            END
        )
      - AVG(
            CASE 
                WHEN TO_DATE("date") >= '2019-01-01'
                 AND TO_DATE("date") <  '2020-01-01'
                THEN TRY_CAST("symptom_anxiety" AS FLOAT)
            END
        )
    )
    /
    AVG(
        CASE 
            WHEN TO_DATE("date") >= '2019-01-01'
             AND TO_DATE("date") <  '2020-01-01'
            THEN TRY_CAST("symptom_anxiety" AS FLOAT)
        END
    ) * 100                                            AS "anxiety_pct_increase",

    (
        AVG(
            CASE 
                WHEN TO_DATE("date") >= '2020-01-01'
                 AND TO_DATE("date") <  '2021-01-01'
                THEN TRY_CAST("symptom_depression" AS FLOAT)
            END
        )
      - AVG(
            CASE 
                WHEN TO_DATE("date") >= '2019-01-01'
                 AND TO_DATE("date") <  '2020-01-01'
                THEN TRY_CAST("symptom_depression" AS FLOAT)
            END
        )
    )
    /
    AVG(
        CASE 
            WHEN TO_DATE("date") >= '2019-01-01'
             AND TO_DATE("date") <  '2020-01-01'
            THEN TRY_CAST("symptom_depression" AS FLOAT)
        END
    ) * 100                                            AS "depression_pct_increase"

FROM COVID19_SYMPTOM_SEARCH.COVID19_SYMPTOM_SEARCH.SYMPTOM_SEARCH_COUNTRY_WEEKLY
WHERE "country_region_code" = 'US'
  AND TO_DATE("date") >= '2019-01-01'
  AND TO_DATE("date") <  '2021-01-01';