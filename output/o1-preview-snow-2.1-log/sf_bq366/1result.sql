WITH labels_with_counts AS (
  SELECT
    l.value:"description"::STRING AS "label_description",
    COUNT(DISTINCT v."object_id") AS "label_count"
  FROM
    "THE_MET"."THE_MET"."VISION_API_DATA" v,
    LATERAL FLATTEN(input => v."labelAnnotations") l
  GROUP BY
    l.value:"description"::STRING
  HAVING
    COUNT(DISTINCT v."object_id") >= 50
),
period_label_counts AS (
  SELECT
    o."period",
    l.value:"description"::STRING AS "label_description",
    COUNT(DISTINCT o."object_id") AS "count"
  FROM
    "THE_MET"."THE_MET"."OBJECTS" o
  JOIN
    "THE_MET"."THE_MET"."VISION_API_DATA" v
    ON o."object_id" = v."object_id"
  CROSS JOIN LATERAL
    FLATTEN(input => v."labelAnnotations") l
  JOIN
    labels_with_counts lwc
    ON l.value:"description"::STRING = lwc."label_description"
  WHERE
    o."period" IS NOT NULL
  GROUP BY
    o."period",
    l.value:"description"::STRING
),
ranked_labels AS (
  SELECT
    "period",
    "label_description",
    "count",
    ROW_NUMBER() OVER (
      PARTITION BY "period"
      ORDER BY "count" DESC NULLS LAST, "label_description" ASC
    ) AS "rn"
  FROM
    period_label_counts
)
SELECT
  "period" AS "Period",
  "label_description" AS "Label",
  "count" AS "Count"
FROM
  ranked_labels
WHERE
  "rn" <= 3
ORDER BY
  "Period" ASC,
  "Count" DESC NULLS LAST,
  "Label" ASC;