WITH eosin_frames AS (
    SELECT DISTINCT
           t."SOPInstanceUID",
           TRY_TO_NUMBER(t."NumberOfFrames") AS frames
    FROM "IDC"."IDC_V17"."DICOM_ALL" t,
         LATERAL FLATTEN(INPUT => t."SpecimenDescriptionSequence") sd
    WHERE t."collection_name" = 'TCGA-BRCA'
      AND t."Modality" = 'SM'
      AND sd.value::STRING ILIKE '%eosin%'
)
SELECT CAST(SUM(frames) AS NUMBER(38,4)) AS total_frames
FROM eosin_frames;