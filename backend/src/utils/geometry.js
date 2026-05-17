// src/utils/geometry.js

/**
 * Round a coordinate to specified precision
 * @param {number} coord 
 * @param {number} precision 
 */
const roundCoordinate = (coord, precision = 2) => {
  return parseFloat(parseFloat(coord).toFixed(precision));
};

/**
 * Format coordinates for PostGIS insertion
 * Returns a string formatted for ST_GeogFromText('SRID=4326;POINT(lng lat)')
 * @param {number} lat 
 * @param {number} lng 
 */
const formatPoint = (lat, lng) => {
  return `SRID=4326;POINT(${lng} ${lat})`;
};

module.exports = {
  roundCoordinate,
  formatPoint
};
