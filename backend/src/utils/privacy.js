// src/utils/privacy.js

/**
 * Round a coordinate to ~500m precision (2 decimal places)
 * Used for public-facing commute listings on the map
 */
const roundCoordinate = (coord, precision = 2) => {
  return parseFloat(parseFloat(coord).toFixed(precision));
};

/**
 * Apply privacy masking to a commute object.
 * Returns rounded coords for public view.
 */
const applyPublicPrivacy = (commute) => ({
  ...commute,
  source_lat: roundCoordinate(commute.source_lat),
  source_lng: roundCoordinate(commute.source_lng),
  // Destination is less sensitive — show at 3 decimal places (~100m)
  dest_lat: roundCoordinate(commute.dest_lat, 3),
  dest_lng: roundCoordinate(commute.dest_lng, 3),
});

/**
 * Check if a user is an accepted participant of a commute.
 * If yes, return exact coordinates. If no, return rounded.
 */
const applyCoordinatePrivacy = (commute, userId, acceptedParticipantIds = []) => {
  const isCreator  = commute.creator_id === userId;
  const isAccepted = acceptedParticipantIds.includes(userId);

  if (isCreator || isAccepted) {
    return commute; // exact coordinates
  }

  return applyPublicPrivacy(commute);
};

module.exports = { roundCoordinate, applyPublicPrivacy, applyCoordinatePrivacy };
