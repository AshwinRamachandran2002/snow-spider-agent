WITH eosin_slides AS (
    SELECT DISTINCT
           t."SOPInstanceUID",
           TRY_TO_NUMBER(t."NumberOfFrames") AS "frames"
    FROM   IDC.IDC_V17.DICOM_ALL  t,
           LATERAL FLATTEN(INPUT => t."SpecimenDescriptionSequence") f
    WHERE  t."collection_name" = 'TCGA-BRCA'
      AND  t."Modality"        = 'SM'
      AND  LOWER(f.value::STRING) LIKE '%eosin%'          -- eosin-based staining step
)
SELECT SUM("frames") AS "total_frames"
FROM   eosin_slides;