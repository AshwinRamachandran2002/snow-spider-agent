WITH eosin_sm_instances AS (
    SELECT DISTINCT
           t."SOPInstanceUID",
           TRY_TO_NUMBER(t."NumberOfFrames") AS frames
    FROM  IDC.IDC_V17.DICOM_ALL t,
          LATERAL FLATTEN(input => t."SpecimenDescriptionSequence") f
    WHERE t."collection_name" = 'TCGA-BRCA'
      AND t."Modality"        = 'SM'
      AND f.value::STRING ILIKE '%eosin%'
)
SELECT
       SUM(frames) AS total_frames
FROM   eosin_sm_instances;