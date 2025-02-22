-- Task: List all unique embedding medium code meanings from the 'SM' modality in the DICOM dataset's un-nested specimen preparation sequences, along with the count of occurrences for each code meaning, ensuring that the codes are from the SCT coding scheme.

WITH
  SpecimenPreparationSequence_unnested AS (
    SELECT
      d."SOPInstanceUID",
      concept_name_code_sequence.value:"CodeMeaning"::STRING AS "cnc_cm",
      concept_name_code_sequence.value:"CodingSchemeDesignator"::STRING AS "cnc_csd",
      concept_name_code_sequence.value:"CodeValue"::STRING AS "cnc_val",
      concept_code_sequence.value:"CodeMeaning"::STRING AS "ccs_cm",
      concept_code_sequence.value:"CodingSchemeDesignator"::STRING AS "ccs_csd",
      concept_code_sequence.value:"CodeValue"::STRING AS "ccs_val"
    FROM
      "IDC"."IDC_V17"."DICOM_ALL" AS d,
      LATERAL FLATTEN(input => d."SpecimenDescriptionSequence") AS spec_desc,
      LATERAL FLATTEN(input => spec_desc.value:"SpecimenPreparationSequence") AS prep_seq,
      LATERAL FLATTEN(input => prep_seq.value:"SpecimenPreparationStepContentItemSequence") AS prep_step,
      LATERAL FLATTEN(input => prep_step.value:"ConceptNameCodeSequence") AS concept_name_code_sequence,
      LATERAL FLATTEN(input => prep_step.value:"ConceptCodeSequence") AS concept_code_sequence
    WHERE
      d."Modality" = 'SM'
  )
SELECT
  "ccs_cm" AS "embeddingMedium_CodeMeaning",
  COUNT(*) AS "count"
FROM
  SpecimenPreparationSequence_unnested
WHERE
  "cnc_csd" = 'SCT' AND "cnc_val" = '430863003' -- 'Embedding medium'
GROUP BY
  "ccs_cm"
ORDER BY
  "count" DESC;