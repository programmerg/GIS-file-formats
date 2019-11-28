
-- Generate GeoJSON from SQL
SELECT row_to_json(featurecollection) As collection
FROM (
  SELECT
    'FeatureCollection' As type,
    json_build_object(
      'type', 'name', 
      'properties', json_build_object('name', concat('EPSG:', 3857))
    ) As crs,
    array_to_json(COALESCE(array_agg(feature),'{}')) As features
  FROM (
    SELECT
      'Feature' As type,
      id As id,
      ST_AsGeoJSON(ST_Transform(geom, 3857), 9, 0)::json As geometry,
      row_to_json(layer.*) As properties -- exclude layer.geom
    FROM tablename As layer
    WHERE ST_Transform(geom, 3857) 
      && ST_MakeEnvelope(minX, minY, maxX, maxY, 3857)
      -- check that the bbox of the geometry overlaps the tile bbox
      AND ST_Intersects(
        ST_Transform(geom, 3857),
        ST_MakeEnvelope(minX, minY, maxX, maxY, 3857)
      ) -- check that the geometry overlaps the tile bbox
  ) As feature
) As featurecollection
