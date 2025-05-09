WITH eosin_wsi AS (
    SELECT DISTINCT
           d."SOPInstanceUID",
           TRY_TO_NUMBER(d."NumberOfFrames") AS "frames"
    FROM  "IDC"."IDC_V17"."DICOM_ALL" d,
          LATERAL FLATTEN ( INPUT => d."SpecimenDescriptionSequence" ) f
    WHERE d."collection_id" = 'tcga_brca'        -- TCGA-BRCA collection
      AND d."Modality"      = 'SM'               -- whole-slide microscopy modality
      AND f.value::STRING ILIKE '%eosin%'        -- eosin-based staining step
      AND TRY_TO_NUMBER(d."NumberOfFrames") > 1  -- keep multi-frame (WSI) objects
)
SELECT SUM("frames") AS "Total_Eosin_Frames"
FROM   eosin_wsi;