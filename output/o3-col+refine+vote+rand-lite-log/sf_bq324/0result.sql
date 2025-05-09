WITH eosin_wsi AS (
    SELECT DISTINCT
           d."SOPInstanceUID",
           TO_NUMBER(d."NumberOfFrames") AS num_frames
    FROM   IDC.IDC_V17.DICOM_ALL d,
           LATERAL FLATTEN(input => d."SpecimenDescriptionSequence") desc1,
           LATERAL FLATTEN(input => desc1.value:"SpecimenPreparationSequence") prep
    WHERE  d."collection_id" = 'tcga_brca'
      AND  d."Modality"      = 'SM'
      AND  d."NumberOfFrames" IS NOT NULL
      AND  prep.value::STRING ILIKE '%eosin%'      -- eosin-based staining step
)
SELECT SUM(num_frames) AS total_eosin_wsi_frames
FROM   eosin_wsi;