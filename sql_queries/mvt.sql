
-- Generate Mapbox Vector Tiles from SQL
SELECT ST_AsMVT(features, 'tablename', 4096, 'geom', 'id')
FROM (
  SELECT 
    layer.id as id,
    ST_AsMvtGeom(
      ST_SimplifyPreserveTopology(ST_Transform(geom, 3857), 156412.0 / 2 ^ tileZ),
      ST_TileEnvelope(tileZ, tileX, tileY), -- bounds of the tile (x, y, z)
      4096, -- tile extent, grid dimensions will be 4096x4096
      256,  -- 256 grid cells in addition to the tile extent
      true  -- geometries will be clipped at the grid + buffer boundaries
    ) AS geom,
    layer.* -- exclude layer.id and layer.geom
  FROM tablename As layer
  WHERE ST_Transform(geom, 3857) 
    && ST_Transform(ST_TileEnvelope(tileZ, tileX, tileY), 3857)
    -- check that the bbox of the geometry overlaps the tile bbox
    AND ST_Intersects(
      ST_Transform(geom, 3857), 
      ST_Transform(ST_TileEnvelope(tileZ, tileX, tileY), 3857)
    ) -- check that the geometry overlaps the tile bbox
) AS features;

-- this funcion is part of PostGIS 3.0
CREATE OR REPLACE FUNCTION ST_TileEnvelope(
  zoom integer, x integer, y integer
) 
RETURNS geometry AS $$
  DECLARE
    max numeric := 6378137 * pi();
    res numeric := max * 2 / 2^zoom;
    bbox geometry;
  BEGIN
    return ST_MakeEnvelope(
        -max + (x * res),
        max - (y * res),
        -max + (x * res) + res,
        max - (y * res) - res,
        3857);
  END;
$$
LANGUAGE plpgsql IMMUTABLE;
