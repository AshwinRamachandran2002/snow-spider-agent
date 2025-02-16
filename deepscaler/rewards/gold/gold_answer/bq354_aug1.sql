-- Task: Provide the standard concept IDs mapped from ICD-10-CM codes L70 (Acne), L20 (Atopic dermatitis), L40 (Psoriasis), and L80 (Vitiligo) along with their skin condition labels
WITH skin_condition_ICD_concept_ids AS (
    SELECT
        concept_id,
        CASE concept_code
            WHEN 'L70' THEN 'Acne'
            WHEN 'L20' THEN 'Atopic dermatitis'
            WHEN 'L40' THEN 'Psoriasis'
            WHEN 'L80' THEN 'Vitiligo'
        END AS skin_condition
    FROM
        `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
    WHERE
        concept_code IN ('L70', 'L20', 'L40', 'L80')
        AND vocabulary_id = 'ICD10CM'
)
SELECT
    s.skin_condition,
    r.concept_id_2 AS standard_concept_id
FROM
    skin_condition_ICD_concept_ids s
JOIN
    `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` r
ON
    s.concept_id = r.concept_id_1
WHERE
    r.relationship_id = 'Maps to'