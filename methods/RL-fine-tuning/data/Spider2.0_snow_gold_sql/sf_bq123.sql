WITH question_answers AS (
  SELECT
    q."id" AS "question_id",
    q."creation_date" AS "question_created",
    TRIM(UPPER(DAYNAME(TO_TIMESTAMP_NTZ(q."creation_date" / 1e6)))) AS "Day_of_week",
    MIN(a."creation_date") AS "earliest_answer_created"
  FROM
    "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
  LEFT JOIN
    "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
    ON q."id" = a."parent_id"
  GROUP BY
    q."id",
    q."creation_date"
),
percentages AS (
  SELECT
    "Day_of_week",
    ROUND(
      (SUM(
        CASE
          WHEN "earliest_answer_created" IS NOT NULL AND
               ("earliest_answer_created" - "question_created") / 1e6 <= 3600
          THEN 1 ELSE 0 END
      ) / COUNT(*)) * 100, 4
    ) AS "Percentage"
  FROM
    question_answers
  GROUP BY
    "Day_of_week"
),
ranked_percentages AS (
  SELECT
    "Day_of_week",
    "Percentage",
    DENSE_RANK() OVER (ORDER BY "Percentage" DESC NULLS LAST) AS "rank"
  FROM
    percentages
)
SELECT
  "Day_of_week",
  "Percentage"
FROM
  ranked_percentages
WHERE
  "rank" = 3;