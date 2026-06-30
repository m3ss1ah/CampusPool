const db = require('../../config/db');

const getProfile = async (userId) => {
  const query = `
    SELECT id, full_name, email, phone, college, profile_pic_url, 
           has_vehicle, vehicle_type, total_rides_offered, 
           total_rides_joined, created_at
    FROM users 
    WHERE id = $1
  `;
  const { rows } = await db.query(query, [userId]);
  return rows[0];
};

const updateProfile = async (userId, updates) => {
  const { full_name, phone, college, has_vehicle, vehicle_type, profile_pic_url } = updates;
  
  // Build dynamic update query
  const fields = [];
  const values = [];
  let index = 1;

  if (full_name !== undefined) { fields.push(`full_name = $${index++}`); values.push(full_name); }
  if (phone !== undefined) { fields.push(`phone = $${index++}`); values.push(phone); }
  if (college !== undefined) { fields.push(`college = $${index++}`); values.push(college); }
  if (has_vehicle !== undefined) { fields.push(`has_vehicle = $${index++}`); values.push(has_vehicle); }
  if (vehicle_type !== undefined) { fields.push(`vehicle_type = $${index++}`); values.push(vehicle_type); }
  if (profile_pic_url !== undefined) { fields.push(`profile_pic_url = $${index++}`); values.push(profile_pic_url); }

  if (fields.length === 0) return await getProfile(userId);

  values.push(userId);
  const query = `
    UPDATE users 
    SET ${fields.join(', ')}, updated_at = NOW() 
    WHERE id = $${index} 
    RETURNING id, full_name, email, phone, college, profile_pic_url, 
              has_vehicle, vehicle_type, total_rides_offered, 
              total_rides_joined, created_at
  `;
  
  const { rows } = await db.query(query, values);
  return rows[0];
};

module.exports = {
  getProfile,
  updateProfile,
};
