SELECT DISTINCT t2."StudyInstanceUID"
FROM (
    /* studies that have a T2-weighted axial MR series */
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17."DICOM_PIVOT"
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%t2%'     -- T2-weighted
      AND "SeriesDescription" ILIKE '%ax%'     -- axial
) t2
JOIN (
    /* studies that contain a segmentation of the peripheral prostate zone */
    SELECT DISTINCT s."StudyInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS" s
    JOIN IDC.IDC_V17."DICOM_PIVOT" p
      ON p."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE p."collection_id" = 'qin_prostate_repeatability'
      AND s."SegmentedPropertyType" ILIKE '%peripheral%zone%'
) seg
  ON t2."StudyInstanceUID" = seg."StudyInstanceUID";