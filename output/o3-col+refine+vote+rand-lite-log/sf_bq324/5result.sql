WITH eosin_instances AS (
    SELECT DISTINCT
           d."SOPInstanceUID",
           TRY_TO_NUMBER(d."NumberOfFrames") AS "frames"
    FROM  IDC.IDC_V17.DICOM_ALL d,
          LATERAL FLATTEN(input => d."SpecimenDescriptionSequence")            s,
          LATERAL FLATTEN(input => s.value:"SpecimenPreparationSequence")      prep,
          LATERAL FLATTEN(input => prep.value:"SpecimenPreparationStepContentItemSequence") step,
          LATERAL FLATTEN(input => step.value)                                 step_item
    WHERE d."Modality"      = 'SM'
      AND d."collection_id" = 'tcga_brca'
      AND LOWER(step_item.value::STRING) LIKE '%eosin%'        -- eosin-based staining
)
SELECT SUM("frames") AS "total_eosin_frames"
FROM   eosin_instances;